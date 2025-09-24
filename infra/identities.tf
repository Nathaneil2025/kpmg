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
# Reference existing ACR
# -----------------------------
data "azurerm_container_registry" "chatbot_acr" {
  name                = "myacr2025kpm"          # ✅ updated ACR name
  resource_group_name = "platform_candidate_2"  # ✅ updated resource group
}

# -----------------------------
# ACR Pull Role Assignment for AKS kubelet identity
# -----------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.chatbot_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.chatbot_acr.id
}
