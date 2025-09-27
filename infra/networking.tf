# ============================
# Virtual Network
# ============================
resource "azurerm_virtual_network" "main_vnet" {
  name                = "chatbot-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["192.168.0.0/16"]

  tags = {
    environment = "chatbot"
  }
}

# ============================
# Subnets (Only what's needed)
# ============================
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.3.0/24"]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

# ============================
# Network Security Groups
# ============================

# Application Gateway NSG
resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "appgw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# ============================
# Application Gateway NSG Rules
# ============================

# Allow Front Door to Application Gateway
resource "azurerm_network_security_rule" "allow_frontdoor_to_appgw" {
  name                        = "Allow-FrontDoor-to-AppGW"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"
  destination_address_prefix  = "192.168.3.0/24"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# Allow Internet to Application Gateway (since APIM is now public)
resource "azurerm_network_security_rule" "allow_internet_to_appgw" {
  name                        = "Allow-Internet-to-AppGW"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "192.168.3.0/24"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# Application Gateway infrastructure requirements
resource "azurerm_network_security_rule" "allow_appgw_infrastructure" {
  name                        = "Allow-AppGW-Infrastructure"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# ============================
# NSG Associations
# ============================

# Associate NSG with Application Gateway subnet
resource "azurerm_subnet_network_security_group_association" "appgw_nsg_association" {
  subnet_id                 = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}