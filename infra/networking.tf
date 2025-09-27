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
# Subnets
# ============================
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = "apim-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.3.0/24"]
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

# API Management NSG
resource "azurerm_network_security_group" "apim_nsg" {
  name                = "apim-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# ============================
# Application Gateway NSG Rules
# ============================

# Allow API Management to Application Gateway (Internal communication)
resource "azurerm_network_security_rule" "allow_apim_to_appgw" {
  name                        = "Allow-APIM-to-AppGW"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "192.168.1.0/24"  # APIM subnet
  destination_address_prefix  = "192.168.3.0/24"  # AppGW subnet
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# Allow Front Door to Application Gateway (External access via public IP)
resource "azurerm_network_security_rule" "allow_frontdoor_to_appgw" {
  name                        = "Allow-FrontDoor-to-AppGW"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"  # Azure Front Door service tag
  destination_address_prefix  = "192.168.3.0/24"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

# Application Gateway infrastructure requirements (required ports)
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
# API Management NSG Rules
# ============================

# Allow Front Door to APIM
resource "azurerm_network_security_rule" "allow_frontdoor_to_apim" {
  name                        = "Allow-FrontDoor-to-APIM"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"
  destination_address_prefix  = "192.168.1.0/24"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Allow API Management management traffic
resource "azurerm_network_security_rule" "allow_apim_management" {
  name                        = "Allow-APIM-Management"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Deny Internet to APIM (except Front Door)
resource "azurerm_network_security_rule" "deny_internet_to_apim" {
  name                        = "Deny-Internet-to-APIM"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "192.168.1.0/24"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Allow all outbound TCP
resource "azurerm_network_security_rule" "allow_outbound_tcp" {
  name                        = "Allow-Outbound-TCP"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Allow all outbound UDP
resource "azurerm_network_security_rule" "allow_outbound_udp" {
  name                        = "Allow-Outbound-UDP"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# ============================
# NSG Associations
# ============================

# Associate NSG with Application Gateway subnet
resource "azurerm_subnet_network_security_group_association" "appgw_nsg_association" {
  subnet_id                 = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

# Associate NSG with API Management subnet
resource "azurerm_subnet_network_security_group_association" "apim_assoc" {
  subnet_id                 = azurerm_subnet.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}

# ============================
# Route Tables
# ============================

resource "azurerm_route_table" "apim_rt" {
  name                = "apim-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

resource "azurerm_subnet_route_table_association" "apim_subnet_rt" {
  subnet_id      = azurerm_subnet.apim_subnet.id
  route_table_id = azurerm_route_table.apim_rt.id
}