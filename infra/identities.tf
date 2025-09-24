# Managed identity for AKS (control plane)
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "chatbot-aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# Managed identity for workloads (pods needing access to Key Vault, Cosmos, Redis)
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "chatbot-workload-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# Role Assignment: allow AKS identity to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.chatbot_acr.id
}

# Role Assignment: allow workload identity to read secrets from Key Vault (will add Key Vault later)
# resource "azurerm_role_assignment" "workload_kv_secrets" {
#   principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
#   role_definition_name = "Key Vault Secrets User"
#   scope                = azurerm_key_vault.chatbot_kv.id
# }

# Role Assignment: allow workload identity to access Cosmos DB (later when Cosmos is defined)
# resource "azurerm_role_assignment" "workload_cosmos_access" {
#   principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
#   role_definition_name = "Cosmos DB Account Reader Role"
#   scope                = azurerm_cosmosdb_account.chatbot_cosmos.id
# }

# Role Assignment: allow workload identity to access Redis (later)
# resource "azurerm_role_assignment" "workload_redis_access" {
#   principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
#   role_definition_name = "Contributor"
#   scope                = azurerm_redis_cache.chatbot_redis.id
# }

# Role Assignment: allow your human admin user MFA account to be AKS Cluster Admin
resource "azurerm_role_assignment" "human_cluster_admin" {
  principal_id         = "86cc998c-7920-4c2e-9daa-bc835f61f5da" # <-- this stays your real Entra ID Object ID
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
}
