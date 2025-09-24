resource "azurerm_container_registry" "chatbot_acr" {
  name                = "chatbotacr2025" # must be globally unique, lowercase only
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  admin_enabled       = false  # we will use managed identities instead of admin user

  tags = {
    environment = "chatbot"
  }
}
