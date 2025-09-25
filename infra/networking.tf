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

  tags = {
    environment = "chatbot"
  }
}

resource "azurerm_subnet_network_security_group_association" "apim_assoc" {
  subnet_id                 = azurerm_subnet.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}
