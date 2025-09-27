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
  url      = "http://${azurerm_public_ip.appgw_public_ip.ip_address}"

  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_application_gateway.chatbot_appgw
  ]
}

# API Definition
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

# Chat Operation - POST /chat
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

# Policy - Routes to Application Gateway Backend
resource "azurerm_api_management_api_policy" "chatbot_routing_policy" {
  api_name            = azurerm_api_management_api.chatbot_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <rate-limit calls="10" renewal-period="60" />
    <set-backend-service backend-id="chatbot-appgw-backend" />
    <rewrite-uri template="/" copy-unmatched-params="true" />
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