import os, json, time, uuid, asyncio
from collections import deque, defaultdict
from typing import Optional, Dict, Any, List

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import httpx

# --- Optional Redis client (only if USE_REDIS=true and REDIS_URL set) ---
try:
    import redis.asyncio as aioredis  # redis>=5
except Exception:
    aioredis = None

APP_NAME = "chatbot-service"
VERSION = "0.1.0"

# ------------------ Config ------------------
AOAI_ENDPOINT = os.getenv("AOAI_ENDPOINT", "").strip().rstrip("/")
AOAI_DEPLOYMENT = os.getenv("AOAI_DEPLOYMENT", "").strip()
AOAI_API_KEY = os.getenv("AOAI_API_KEY", "").strip()

USE_REDIS = os.getenv("USE_REDIS", "false").lower() == "true"
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Cosmos (mocked locally for now)
USE_COSMOS = os.getenv("USE_COSMOS", "false").lower() == "true"  # when true, you can later swap to real SDK
COSMOS_FILE = os.getenv("COSMOS_FILE", "./cosmos_mock.json")     # durable local JSON “DB”

# Limits & timeouts
AOAI_TIMEOUT_SECS = int(os.getenv("AOAI_TIMEOUT_SECS", "20"))
REQ_TIMEOUT_SECS = int(os.getenv("REQ_TIMEOUT_SECS", "25"))
RATE_LIMIT_PER_MIN = int(os.getenv("RATE_LIMIT_PER_MIN", "10"))  # per IP

# ------------------ Models ------------------
class ChatRequest(BaseModel):
    session_id: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)

class ChatResponse(BaseModel):
    session_id: str
    reply: str
    tokens_used: Optional[int] = 0
    source: str = "mock"  # "aoai" if real call was used

# ------------------ App & Globals ------------------
app = FastAPI(title=APP_NAME, version=VERSION)

# In-memory rate limiter store: ip -> deque[timestamps]
rate_buckets: Dict[str, deque] = defaultdict(lambda: deque(maxlen=128))

# In-memory fallback session store (if no Redis):
mem_sessions: Dict[str, List[Dict[str, str]]] = defaultdict(list)

# Redis handle (lazy)
redis_client = None

# ------------------ Utilities ------------------
def now_ms() -> int:
    return int(time.time() * 1000)

def json_log(event: str, **fields):
    payload = {"event": event, "ts": now_ms(), "service": APP_NAME, **fields}
    print(json.dumps(payload, ensure_ascii=False))

async def get_redis():
    global redis_client
    if not USE_REDIS:
        return None
    if aioredis is None:
        json_log("redis_import_missing")
        return None
    if redis_client is None:
        redis_client = aioredis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
    return redis_client

def load_cosmos_file() -> Dict[str, Any]:
    try:
        if os.path.exists(COSMOS_FILE):
            with open(COSMOS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception as e:
        json_log("cosmos_file_load_error", error=str(e))
    return {}

def save_cosmos_file(data: Dict[str, Any]) -> None:
    try:
        with open(COSMOS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        json_log("cosmos_file_save_error", error=str(e))

async def rate_limit_or_429(ip: str):
    bucket = rate_buckets[ip]
    now = time.time()
    # drop old
    while bucket and now - bucket[0] > 60:
        bucket.popleft()
    if len(bucket) >= RATE_LIMIT_PER_MIN:
        raise HTTPException(status_code=429, detail="Rate limit exceeded (10 req/min).")
    bucket.append(now)

async def fetch_first_10_from_redis(session_id: str) -> List[Dict[str, str]]:
    r = await get_redis()
    if not r:
        # fallback to memory
        return mem_sessions.get(session_id, [])[:10]
    items = await r.lrange(f"sess:{session_id}", 0, 9)  # store serialized JSON per msg
    return [json.loads(x) for x in items]

async def append_to_redis(session_id: str, msg: Dict[str, str]):
    r = await get_redis()
    if not r:
        mem_sessions[session_id].append(msg)
        # keep at most 10 in mem for “redis layer”
        mem_sessions[session_id] = mem_sessions[session_id][:10]
        return
    await r.rpush(f"sess:{session_id}", json.dumps(msg))
    # trim to first 10
    await r.ltrim(f"sess:{session_id}", 0, 9)

def append_to_cosmos_mock(session_id: str, msgs: List[Dict[str, str]]):
    # stores “beyond 10” messages; simple, predictable, durable locally
    db = load_cosmos_file()
    entry = db.get(session_id, {"beyond10": []})
    entry["beyond10"].extend(msgs)
    db[session_id] = entry
    save_cosmos_file(db)

def get_beyond10_from_cosmos_mock(session_id: str) -> List[Dict[str, str]]:
    db = load_cosmos_file()
    return db.get(session_id, {}).get("beyond10", [])

async def full_history(session_id: str) -> List[Dict[str, str]]:
    first10 = await fetch_first_10_from_redis(session_id)
    rest = get_beyond10_from_cosmos_mock(session_id)
    return first10 + rest

async def add_message(session_id: str, role: str, content: str):
    # figure where to store
    hist = await full_history(session_id)
    msg = {"role": role, "content": content, "ts": now_ms()}
    if len(hist) < 10:
        await append_to_redis(session_id, msg)
    else:
        append_to_cosmos_mock(session_id, [msg])

# ------------------ Azure OpenAI or Mock ------------------
async def call_aoai_or_mock(messages: List[Dict[str, str]]) -> (str, str, int):
    """
    Returns: (reply, source, tokens_used)
    """
    if AOAI_ENDPOINT and AOAI_DEPLOYMENT and AOAI_API_KEY:
        url = f"{AOAI_ENDPOINT}/openai/deployments/{AOAI_DEPLOYMENT}/chat/completions?api-version=2024-05-01-preview"
        headers = {
            "api-key": AOAI_API_KEY,
            "Content-Type": "application/json",
        }
        body = {
            "messages": messages,
            "temperature": 0.2,
            "top_p": 0.9,
        }
        try:
            async with httpx.AsyncClient(timeout=AOAI_TIMEOUT_SECS) as client:
                resp = await client.post(url, headers=headers, json=body)
                resp.raise_for_status()
                data = resp.json()
                reply = data["choices"][0]["message"]["content"]
                usage = data.get("usage", {})
                tokens = int(usage.get("total_tokens", 0))
                return reply, "aoai", tokens
        except Exception as e:
            json_log("aoai_error", error=str(e))
            # graceful fallback → keep mock
    # fallback mock
    last_user = next((m["content"] for m in reversed(messages) if m["role"] == "user"), "")
    context_hint = "I’m a helpful enterprise chatbot. "
    reply = (
        f"{context_hint}You said: '{last_user}'. "
        "Here’s a concise response: I understand your request and will handle it step by step. "
        "If you have specific data or constraints, provide them and I’ll adapt the plan."
    )
    tokens = max(20, len(last_user) // 3)
    return reply, "mock", tokens


# ------------------ Middleware ------------------
@app.middleware("http")
async def request_timer(request: Request, call_next):
    rid = request.headers.get("x-request-id", str(uuid.uuid4()))
    request.state.rid = rid
    client_ip = request.client.host if request.client else "unknown"
    try:
        await asyncio.wait_for(rate_limit_or_429(client_ip), timeout=1.0)
        start = time.time()
        response = await asyncio.wait_for(call_next(request), timeout=REQ_TIMEOUT_SECS)
        dur_ms = int((time.time() - start) * 1000)
        json_log("request_done", path=str(request.url.path), rid=rid, ip=client_ip, ms=dur_ms, status=getattr(response, "status_code", 200))
        response.headers["x-request-id"] = rid
        return response
    except asyncio.TimeoutError:
        json_log("request_timeout", path=str(request.url.path), rid=rid)
        return JSONResponse(status_code=504, content={"detail": "Request timed out"})
    except HTTPException as he:
        json_log("request_http_error", path=str(request.url.path), rid=rid, status=he.status_code, detail=str(he.detail))
        raise
    except Exception as e:
        json_log("request_error", path=str(request.url.path), rid=rid, error=str(e))
        return JSONResponse(status_code=500, content={"detail": "Internal server error"})

# ------------------ Routes ------------------
@app.get("/")
async def root():
    return {"message": "Chatbot API is running"}

@app.get("/healthz")
async def healthz():
    return {"status": "ok", "service": APP_NAME, "version": VERSION}

@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest, request: Request):
    rid = request.state.rid
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message is empty")

    # system prompt (clean default, English-only)
    system_prompt = (
        "You are a helpful enterprise chatbot. Be concise, factual, and professional. "
        "Use clear English. If information is missing, ask for the minimal clarification."
    )

    # Build conversation
    history = await full_history(req.session_id)
    messages = [{"role": "system", "content": system_prompt}] + history + [
        {"role": "user", "content": req.message}
    ]

    # Persist user message according to the 10/Rest policy
    await add_message(req.session_id, role="user", content=req.message)

    reply, source, tokens = await call_aoai_or_mock(messages)

    # Save assistant reply (also follows 10/Rest policy)
    await add_message(req.session_id, role="assistant", content=reply)

    json_log("chat_reply", rid=rid, session=req.session_id, source=source, tokens=tokens)
    return ChatResponse(session_id=req.session_id, reply=reply, tokens_used=tokens, source=source)
