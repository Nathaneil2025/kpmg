resource "azurerm_virtual_network" "main_vnet" {
  name                = "chatbot-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["192.168.0.0/16"]

  tags = {
    environment = "chatbot"
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

# -------------------
# Subnet Delegation (critical for APIM)
# -------------------
resource "azurerm_subnet" "apim_subnet" {
  name                 = "apim-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["192.168.1.0/24"]

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
}

resource "azurerm_subnet_route_table_association" "apim_subnet_rt" {
  subnet_id      = azurerm_subnet.apim_subnet.id
  route_table_id = azurerm_route_table.apim_rt.id
}
