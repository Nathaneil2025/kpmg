resource "azurerm_api_management" "chatbot_apim" {
  name                = "chatbot-apim-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "Chatbot Team"
  publisher_email     = "admin@example.com"

  sku_name = "Developer_1" # For dev/test only

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

  depends_on = [
    azurerm_subnet_network_security_group_association.apim_assoc
  ]
}


# Define the API object but don’t bind backend here
resource "azurerm_api_management_api" "chatbot_api" {
  name                = "chatbot-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.chatbot_apim.name
  revision            = "1"
  display_name        = "Chatbot API"
  path                = "chat"
  protocols           = ["https"]

  import {
    content_format = "swagger-link-json"
    # Dummy placeholder for now; CI/CD replaces this later
    content_value  = "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/examples/v3.0/petstore.json"
  }
}

# Rate limit policy stays valid (backend is updated later)
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

  # ✅ Ensure APIM + API are ready first
  depends_on = [
    azurerm_api_management.chatbot_apim,
    azurerm_api_management_api.chatbot_api
  ]
}

resource "azurerm_network_security_group" "apim_nsg" {
  name                = "apim-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
  name                       = "AllowOutboundMgmt"
  priority                   = 200
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["443", "3442", "3443"]
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}


  # ✅ Required for APIM management plane
  security_rule {
    name                       = "AllowManagement"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3443", "3442"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "chatbot"
  }
}

