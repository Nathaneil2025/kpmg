resource "azurerm_redis_cache" "chatbot_redis" {
  name                = "chatbot-redis-2025" # must be globally unique
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  minimum_tls_version = "1.2"
  public_network_access_enabled = true # later can be locked down to private

  tags = {
    environment = "chatbot"
  }
}

# Role Assignment: allow workload identity to access Redis
resource "azurerm_role_assignment" "workload_redis_access" {
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_redis_cache.chatbot_redis.id
}
