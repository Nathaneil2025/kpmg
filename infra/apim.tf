resource "azurerm_api_management" "chatbot_apim" {
  name                = "chatbot-apim-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "Chatbot Team"
  publisher_email     = "admin@example.com"
  sku_name            = "Developer_1"

  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "chatbot"
  }

  # APIM waits until NSG + RT are attached to subnet
  depends_on = [
    azurerm_subnet_network_security_group_association.apim_assoc,
    azurerm_subnet_route_table_association.apim_subnet_rt
  ]
}

resource "azurerm_api_management_api" "chatbot_api" {
  name                = "chatbot-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.chatbot_apim.name
  revision            = "1"
  display_name        = "Chatbot API"
  path                = "chat"
  protocols           = ["https"]

  import {
    content_format = "openapi-link"
    content_value  = "https://aoai-candidates-east-us-2.openai.azure.com/openai/docs/openapi.json?api-version=2023-12-01-preview"
  }
}

#resource "azurerm_api_management_api" "chatbot_api" {
#  name                = "chatbot-api"
#  resource_group_name = var.resource_group_name
#  api_management_name = azurerm_api_management.chatbot_apim.name
#  revision            = "1"
#  display_name        = "Chatbot API"
#  path                = "chat"
#  protocols           = ["https"]

#  import {
#    content_format = "openapi-link"
#    content_value  = "https://aoai-candidates-east-us-2.openai.azure.com/openai/docs/openapi.json?api-version=2023-12-01-preview"
#  }
#}

resource "azurerm_api_management_api_policy" "rate_limit_policy" {
  api_name            = azurerm_api_management_api.chatbot_api.name
  api_management_name = azurerm_api_management.chatbot_apim.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <rate-limit calls="10" renewal-period="60" />
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
</policies>
XML

  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_api_management_api.chatbot_api
  ]
}
