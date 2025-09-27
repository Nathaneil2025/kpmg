resource "azurerm_static_site" "chatbot_frontend" {
  name                = "chatbot-frontend-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_tier            = "Free"
}
