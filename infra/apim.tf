# API Management Service - Remove VNet Integration
resource "azurerm_api_management" "chatbot_apim" {
  name                = "chatbot-apim-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "Chatbot Team"
  publisher_email     = "admin@example.com"
  sku_name            = "Developer_1"

  # Remove these lines completely:
  # virtual_network_type = "External"
  # virtual_network_configuration {
  #   subnet_id = azurerm_subnet.apim_subnet.id
  # }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "chatbot"
  }

  # Remove VNet dependencies:
  # depends_on = [
  #   azurerm_subnet_network_security_group_association.apim_assoc,
  #   azurerm_subnet_route_table_association.apim_subnet_rt
  # ]
}