# -----------------------------
# AKS Outputs
# -----------------------------

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

# -----------------------------
# ACR Outputs
# -----------------------------

# ACR Login Server (points to myacrtask in platform_candidate_2)
output "acr_login_server" {
  value = data.azurerm_container_registry.chatbot_acr.login_server
}


# -----------------------------
# Identity Outputs
# -----------------------------

# AKS Control Plane Identity (User Assigned)
output "aks_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_identity.client_id
}

output "aks_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_identity.principal_id
}

# Workload Identity (used by pods for KV, Redis, Cosmos)
output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload_identity.client_id
}

output "workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.workload_identity.principal_id
}

# Application Gateway Identity (for cert fetch from Key Vault)
output "appgw_identity_client_id" {
  value = azurerm_user_assigned_identity.appgw_identity.client_id
}

output "appgw_identity_principal_id" {
  value = azurerm_user_assigned_identity.appgw_identity.principal_id
}


# -----------------------------
# Role Assignment Outputs
# -----------------------------

# AppGW identity -> Key Vault (for TLS certs)
output "appgw_kv_role_assignment" {
  description = "Role assignment ID for AppGW Key Vault Secrets User"
  value       = azurerm_role_assignment.appgw_kv_secrets_user.id
}

# AppGW identity -> Resource Group (Reader)
output "appgw_rg_reader_assignment" {
  description = "Role assignment ID for AppGW Reader on RG"
  value       = azurerm_role_assignment.appgw_rg_reader.id
}

# AppGW identity -> Application Gateway (Contributor)
output "appgw_contributor_assignment" {
  description = "Role assignment ID for AppGW Contributor on Application Gateway"
  value       = azurerm_role_assignment.appgw_contributor.id
}
