# Front Door Premium profile
resource "azurerm_cdn_frontdoor_profile" "chatbot_fd" {
  name                = "chatbot-fd-2025"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = {
    environment = "chatbot"
  }
}

# Endpoint
# Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "chatbot_fd_endpoint" {
  name                     = "chatbot-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.chatbot_fd.id
}

# Origin group
resource "azurerm_cdn_frontdoor_origin_group" "chatbot_fd_origin_group" {
  name                     = "chatbot-fd-origingroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.chatbot_fd.id

  health_probe {
    path                = "/"
    protocol            = "Https"
    interval_in_seconds = 30
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
  }
}

# Origin (APIM gateway)
resource "azurerm_cdn_frontdoor_origin" "chatbot_fd_origin" {
  name                          = "chatbot-apim-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.chatbot_fd_origin_group.id

  # must be hostname only, no scheme
  host_name          = replace(azurerm_api_management.chatbot_apim.gateway_url, "https://", "")
  origin_host_header = replace(azurerm_api_management.chatbot_apim.gateway_url, "https://", "")

  http_port                     = 80
  https_port                    = 443
  enabled                       = true
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# Route
resource "azurerm_cdn_frontdoor_route" "chatbot_fd_route" {
  name                          = "chatbot-fd-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.chatbot_fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.chatbot_fd_origin_group.id

  # 🔑 This is required
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.chatbot_fd_origin.id
  ]

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true

  depends_on = [azurerm_api_management.chatbot_apim]
}
