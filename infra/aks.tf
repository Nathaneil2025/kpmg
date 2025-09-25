resource "azurerm_kubernetes_cluster" "chatbot_aks" {
  name                = "chatbot-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "chatbotaks"

  kubernetes_version  = "1.33.3"

  default_node_pool {
    name            = "systempool"
    node_count      = 2
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
    type            = "VirtualMachineScaleSets"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  network_profile {
    network_plugin   = "azure"
    service_cidr     = "10.0.0.0/16"
    dns_service_ip   = "10.0.0.10"
    outbound_type    = "loadBalancer"
  }

  role_based_access_control_enabled = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = {
    environment = "chatbot"
  }
}
