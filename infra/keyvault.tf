resource "azurerm_key_vault" "chatbot_kv" {
  name                        = "chatbot-kv-2025"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  purge_protection_enabled      = true
  public_network_access_enabled = true

  tags = {
    environment = "chatbot"
  }
}

# Role Assignment: allow workload identity (AKS pod MSI) to read secrets
resource "azurerm_role_assignment" "workload_kv_secrets" {
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.chatbot_kv.id
}

# Role Assignment: allow GitHub OIDC federated identity to manage certs/secrets
resource "azurerm_role_assignment" "github_kv_certificates" {
  principal_id         = var.github_oidc_principal_id   # 👈 add this variable
  role_definition_name = "Key Vault Certificates Officer"
  scope                = azurerm_key_vault.chatbot_kv.id
}

resource "azurerm_role_assignment" "github_kv_secrets" {
  principal_id         = var.github_oidc_principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.chatbot_kv.id
}
