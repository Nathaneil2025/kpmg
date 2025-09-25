# -------------------
# API Management
# -------------------
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
    azurerm_subnet_network_security_group_association.apim_assoc,
    azurerm_subnet.apim_subnet
  ]
}

# -------------------
# API Definition
# -------------------
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

# -------------------
# API Policy
# -------------------
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

# -------------------
# APIM NSG
# -------------------
resource "azurerm_network_security_group" "apim_nsg" {
  name                = "apim-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Inbound rules
  security_rule {
    name                       = "AllowClientInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["80", "443"]
  }

  security_rule {
    name                       = "AllowMgmtInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "ApiManagement"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "3443"
  }

  security_rule {
    name                       = "AllowAzureLBInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "6390"
  }

  security_rule {
    name                       = "AllowTrafficManagerInbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureTrafficManager"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "443"
  }

  # Outbound rules
  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
  }

  security_rule {
    name                       = "AllowOutboundStorage"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "Storage"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowOutboundSQL"
    priority                   = 220
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "SQL"
    destination_port_range     = "1433"
  }

  security_rule {
    name                       = "AllowOutboundKeyVault"
    priority                   = 230
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "AzureKeyVault"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowOutboundAzureMonitor"
    priority                   = 240
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "AzureMonitor"
    destination_port_ranges    = ["1886", "443"]
  }

  tags = {
    environment = "chatbot"
  }
}

