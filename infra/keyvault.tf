data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "chatbot_kv" {
  name                        = "chatbot-kv-2025"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
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

  depends_on = [azurerm_key_vault.chatbot_kv]
}

# Role Assignment: allow GitHub service principal full Key Vault admin rights
resource "azurerm_role_assignment" "github_kv_admin" {
  principal_id         = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions SP objectId
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.chatbot_kv.id

  depends_on = [azurerm_key_vault.chatbot_kv]
}

# Role Assignment: allow GitHub service principal to manage certs
resource "azurerm_role_assignment" "github_kv_certificates" {
  principal_id         = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions SP objectId
  role_definition_name = "Key Vault Certificates Officer"
  scope                = azurerm_key_vault.chatbot_kv.id

  depends_on = [azurerm_key_vault.chatbot_kv]
}

# Role Assignment: allow GitHub service principal to read secrets
resource "azurerm_role_assignment" "github_kv_secrets" {
  principal_id         = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions SP objectId
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.chatbot_kv.id

  depends_on = [azurerm_key_vault.chatbot_kv]
}

resource "azurerm_key_vault_access_policy" "appgw_kv_policy" {
  key_vault_id = azurerm_key_vault.chatbot_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw_identity.principal_id

  secret_permissions = [
  
  "Get", 
  "List",
  "Delete",
  "Purge",
  "Recover"
  ]

  certificate_permissions = [
  "Create",
  "Get", 
  "List",
  "Delete",
  "Import",
  "Recover" 
  ]
}


resource "azurerm_key_vault_access_policy" "cicd_kv_policy" {
  key_vault_id = azurerm_key_vault.chatbot_kv.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = "4e4f585b-62da-4b84-88cd-8e247f841622" # GitHub Actions SP objectId

  certificate_permissions = [
    "Create",
    "Get",
    "List",
    "Delete",
    "Import",    # Add this missing permission
    "Recover",
    "Purge" 
  ]

  secret_permissions = [
    "Get",
    "List",
    "Delete",
    "Recover",
    "Purge" 
  ]
}
