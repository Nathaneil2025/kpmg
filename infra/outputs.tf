# AKS Cluster Name
output "aks_name" {
  value = azurerm_kubernetes_cluster.chatbot_aks.name
}

# AKS Resource Group
output "aks_resource_group" {
  value = azurerm_kubernetes_cluster.chatbot_aks.resource_group_name
}

# AKS API Server FQDN
output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.chatbot_aks.fqdn
}

# AKS Kubeconfig (raw, use in CI/CD pipelines)
output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.chatbot_aks.kube_config_raw
  sensitive = true
}

# AKS OIDC Issuer URL (for workload identity, later use with GitHub Actions)
output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.chatbot_aks.oidc_issuer_url
}

# ACR Login Server (so workflows know where to push images)
output "acr_login_server" {
  value = azurerm_container_registry.chatbot_acr.login_server
}
