# API Management Service - No VNet Integration
resource "azurerm_api_management" "chatbot_apim" {
  name                = "chatbot-apim-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "Chatbot Team"
  publisher_email     = "admin@example.com"
  sku_name            = "Developer_1"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "chatbot"
  }
}

# Backend Service pointing to Application Gateway PUBLIC IP
resource "azurerm_api_management_backend" "chatbot_appgw_backend" {
  name                = "chatbot-appgw-backend"
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name

  protocol = "http"
  url      = "http://128.24.101.81"

  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_application_gateway.chatbot_appgw
  ]
}

# API Definition for Chat API (requires subscription key)
resource "azurerm_api_management_api" "chatbot_api" {
  name                = "chatbot-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.chatbot_apim.name
  revision            = "1"
  display_name        = "Chatbot API"
  path                = "chat"
  protocols           = ["https"]

  depends_on = [azurerm_api_management.chatbot_apim]
}

# Chat Operation - POST /chat (API with subscription key)
resource "azurerm_api_management_api_operation" "chat_post" {
  operation_id        = "chat-post"
  api_name           = azurerm_api_management_api.chatbot_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "Chat with Bot"
  method             = "POST"
  url_template       = "/chat"
  description        = "Send message to chatbot"

  request {
    description = "Chat request"

    representation {
      content_type = "application/json"
      example {
        name  = "example"
        value = jsonencode({
          session_id = "testing"
          message    = "What is the capital of Israel?"
        })
      }
    }
  }

  response {
    status_code  = 200
    description  = "Successful response"

    representation {
      content_type = "application/json"
    }
  }

  depends_on = [azurerm_api_management_api.chatbot_api]
}

# Chat API Policy - Routes to Application Gateway Backend
resource "azurerm_api_management_api_policy" "chatbot_routing_policy" {
  api_name            = azurerm_api_management_api.chatbot_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <rate-limit calls="10" renewal-period="60" />
    <set-backend-service backend-id="chatbot-appgw-backend" />
    <set-header name="Host" exists-action="override">
      <value>chatbot.kpmg.local</value>
    </set-header>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_api_management_api.chatbot_api,
    azurerm_api_management_backend.chatbot_appgw_backend,
    azurerm_api_management_api_operation.chat_post
  ]
}

# Website API Definition (for serving the web interface - no subscription required)
resource "azurerm_api_management_api" "chatbot_website_api" {
  name                = "chatbot-website-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.chatbot_apim.name
  revision            = "1"
  display_name        = "Chatbot Website"
  path                = ""
  protocols           = ["https"]
  subscription_required = false

  depends_on = [azurerm_api_management.chatbot_apim]
}

# Root path - GET (login page)
resource "azurerm_api_management_api_operation" "website_root" {
  operation_id        = "website-root"
  api_name           = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "Website Root"
  method             = "GET"
  url_template       = "/"
  description        = "Login page"

  depends_on = [azurerm_api_management_api.chatbot_website_api]
}

# Login form submission - POST
resource "azurerm_api_management_api_operation" "website_login" {
  operation_id        = "website-login"
  api_name           = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "Login Form"
  method             = "POST"
  url_template       = "/login"
  description        = "Handle login form submission"

  depends_on = [azurerm_api_management_api.chatbot_website_api]
}

# Chat UI page - GET
resource "azurerm_api_management_api_operation" "website_chat_ui" {
  operation_id        = "website-chat-ui"
  api_name           = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "Chat Interface"
  method             = "GET"
  url_template       = "/chat-ui"
  description        = "Chat interface page"

  depends_on = [azurerm_api_management_api.chatbot_website_api]
}

# Logout - POST
resource "azurerm_api_management_api_operation" "website_logout" {
  operation_id        = "website-logout"
  api_name           = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "Logout"
  method             = "POST"
  url_template       = "/logout"
  description        = "Handle logout"

  depends_on = [azurerm_api_management_api.chatbot_website_api]
}

# API Chat endpoint for authenticated users - POST
resource "azurerm_api_management_api_operation" "website_api_chat" {
  operation_id        = "website-api-chat"
  api_name           = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name
  display_name       = "API Chat"
  method             = "POST"
  url_template       = "/api/chat"
  description        = "Chat API for authenticated web users"

  depends_on = [azurerm_api_management_api.chatbot_website_api]
}

# Website Policy - Routes to Application Gateway (no authentication required)
resource "azurerm_api_management_api_policy" "chatbot_website_policy" {
  api_name            = azurerm_api_management_api.chatbot_website_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <set-backend-service backend-id="chatbot-appgw-backend" />
    <set-header name="Host" exists-action="override">
      <value>chatbot.kpmg.local</value>
    </set-header>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_api_management_api.chatbot_website_api,
    azurerm_api_management_backend.chatbot_appgw_backend
  ]
}