resource "azurerm_kubernetes_cluster" "chatbot_aks" {
  name                = "chatbot-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "chatbotaks"

  kubernetes_version  = "1.29.2" # adjust to latest available in region

  default_node_pool {
    name                = "systempool"
    node_count          = 2
    vm_size             = "Standard_DS2_v2"
    os_disk_size_gb     = 30
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    type                = "VirtualMachineScaleSets"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  # Wire AKS to ACR
  #depends_on = [azurerm_role_assignment.aks_acr_pull]

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    outbound_type      = "loadBalancer"
  }

  role_based_access_control_enabled = true

  # For GitHub Actions OIDC → AKS (Helm deploys later)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Addon: Application Gateway Ingress Controller (AGIC)


  tags = {
    environment = "chatbot"
  }
}
