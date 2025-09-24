resource "azurerm_key_vault" "chatbot_kv" {
  name                        = "chatbot-kv-2025" # must be globally unique
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  # Soft delete is always enabled now; only configure purge protection
  purge_protection_enabled    = true
  public_network_access_enabled = true # later can be restricted with private endpoints

  tags = {
    environment = "chatbot"
  }
}

# Role Assignment: allow workload identity to read secrets
resource "azurerm_role_assignment" "workload_kv_secrets" {
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.chatbot_kv.id
}
