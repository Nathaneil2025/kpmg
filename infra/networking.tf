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

  # APIM requires delegation
  delegation {
    name = "apim_delegation"
    service_delegation {
      name    = "Microsoft.ApiManagement/service"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

# ============================
# Network Security Group (APIM)
# ============================
resource "azurerm_network_security_group" "apim_nsg" {
  name                = "apim-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowClientInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["80", "443"]
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowMgmtInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["3443"]
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowOutboundStorage"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
    destination_port_range     = "443"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowOutboundSQL"
    priority                   = 220
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "SQL"
    destination_port_range     = "1433"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowOutboundKeyVault"
    priority                   = 230
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
    destination_port_range     = "443"
    source_port_range          = "*"
  }

  security_rule {
    name                       = "AllowOutboundAzureMonitor"
    priority                   = 240
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
    destination_port_ranges    = ["443", "1886"]
    source_port_range          = "*"
  }

  tags = {
    environment = "chatbot"
  }

  # Ensure NSG waits for association to be destroyed first
  depends_on = [
    azurerm_subnet_network_security_group_association.apim_assoc
  ]
}

# ============================
# Associations
# ============================
resource "azurerm_subnet_network_security_group_association" "apim_assoc" {
  subnet_id                 = azurerm_subnet.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}

resource "azurerm_route_table" "apim_rt" {
  name                = "apim-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }

  # Ensure RT waits for association to be destroyed first
  depends_on = [
    azurerm_subnet_route_table_association.apim_subnet_rt
  ]
}

resource "azurerm_subnet_route_table_association" "apim_subnet_rt" {
  subnet_id      = azurerm_subnet.apim_subnet.id
  route_table_id = azurerm_route_table.apim_rt.id
}
