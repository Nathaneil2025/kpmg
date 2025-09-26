# -----------------------------
# Managed identity for AKS control plane
# -----------------------------
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "chatbot-aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# Allow AKS identity to read the App Gateway's resource group
resource "azurerm_role_assignment" "aks_rg_reader" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Reader"
  scope                = data.azurerm_resource_group.chatbot_rg.id
}

# Allow AKS identity full control of the App Gateway
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_application_gateway.chatbot_appgw.id
}

# -----------------------------
# Managed identity for workloads (pods needing access to KV, Cosmos, Redis)
# -----------------------------
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "chatbot-workload-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# -----------------------------
# Managed identity for Application Gateway
# (used only for Key Vault secret/cert access)
# -----------------------------
resource "azurerm_user_assigned_identity" "appgw_identity" {
  name                = "chatbot-appgw-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "chatbot"
  }
}

# Allow AppGW identity -> Key Vault (TLS cert fetch)
resource "azurerm_role_assignment" "appgw_kv_secrets_user" {
  principal_id         = azurerm_user_assigned_identity.appgw_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.chatbot_kv.id

  depends_on = [azurerm_key_vault.chatbot_kv]
}

# -----------------------------
# Role Assignment: allow GitHub Actions SP to be AKS Cluster Admin
# -----------------------------
resource "azurerm_role_assignment" "cicd_cluster_admin" {
  principal_id         = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions SP Object ID
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.chatbot_aks.id
}

# -----------------------------
# Role Assignment: allow your own user to be AKS Cluster Admin
# -----------------------------
resource "azurerm_role_assignment" "human_cluster_admin" {
  principal_id         = "86cc998c-7920-4c2e-9daa-bc835f61f5da" # Your own Entra ID Object ID
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.chatbot_aks.id
}

# -----------------------------
# Role Assignment: AKS kubelet identity -> ACR Pull
# -----------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.chatbot_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.chatbot_acr.id
}

# -----------------------------
# SAFE: Lookup the RG
# -----------------------------
data "azurerm_resource_group" "chatbot_rg" {
  name = var.resource_group_name
}
