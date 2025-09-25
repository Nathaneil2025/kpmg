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
# ACR Pull Role Assignment for AKS kubelet identity
# -----------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.chatbot_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.chatbot_acr.id
}

# -----------------------------
# Role Assignment: allow your human admin user to be AKS Cluster Admin
# -----------------------------
resource "azurerm_role_assignment" "cicd_cluster_admin" {
  principal_id         = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions UAMI/SP Object ID
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.chatbot_aks.id
}

resource "azurerm_role_assignment" "human_cluster_admin" {
  principal_id         = "86cc998c-7920-4c2e-9daa-bc835f61f5da" # Your own Entra ID Object ID
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.chatbot_aks.id
}
