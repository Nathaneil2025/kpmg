# ---------- Build stage ----------
FROM --platform=$BUILDPLATFORM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# requirements.txt is inside the app/ folder in your repo
COPY app/requirements.txt ./requirements.txt

RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir "uvicorn[standard]" "gunicorn==22.*"

# ---------- Run stage ----------
FROM --platform=$TARGETPLATFORM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    WEB_CONCURRENCY=2 \
    GUNICORN_TIMEOUT=30 \
    GUNICORN_KEEPALIVE=5 \
    GUNICORN_MAX_REQUESTS=1000 \
    GUNICORN_MAX_REQUESTS_JITTER=100

# Non-root user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Bring in installed packages from builder
COPY --from=builder /usr/local /usr/local

# Copy your actual application code from repo/app → image /app
COPY app/ /app/

USER app

# Basic healthcheck hitting your /healthz endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,os; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\",\"8080\")}/healthz').read()" || exit 1

EXPOSE 8080

# Default command: Gunicorn with Uvicorn workers
CMD ["sh", "-c", "gunicorn -k uvicorn.workers.UvicornWorker \
  --workers ${WEB_CONCURRENCY} \
  --timeout ${GUNICORN_TIMEOUT} \
  --keep-alive ${GUNICORN_KEEPALIVE} \
  --max-requests ${GUNICORN_MAX_REQUESTS} \
  --max-requests-jitter ${GUNICORN_MAX_REQUESTS_JITTER} \
  --bind 0.0.0.0:${PORT} \
  main:app"]
