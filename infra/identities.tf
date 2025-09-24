# Reference the existing ACR "myacr2025kpm" in resource group "platform_candidate_2"
data "azurerm_container_registry" "chatbot_acr" {
  name                = "myacr2025kpm"
  resource_group_name = "platform_candidate_2"
}

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
# Locals for external ACR
# -----------------------------
locals {
  acr_id = "/subscriptions/${var.subscription_id}/resourceGroups/ai-candidates/providers/Microsoft.ContainerRegistry/registries/acrcandidates"
}

# -----------------------------
# Reference AKS after creation (to fetch kubelet identity cleanly)
# -----------------------------
data "azurerm_kubernetes_cluster" "chatbot_aks" {
  name                = azurerm_kubernetes_cluster.chatbot_aks.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_kubernetes_cluster.chatbot_aks]
}

# -----------------------------
# ACR Pull Role Assignment for AKS kubelet identity
# -----------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = data.azurerm_kubernetes_cluster.chatbot_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.chatbot_acr.id
}
