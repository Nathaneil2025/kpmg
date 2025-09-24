resource "azurerm_cosmosdb_account" "chatbot_cosmos" {
  name                = "chatbot-cosmos-2025" # must be globally unique
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # automatic failover is enabled by default in v3+, no attribute needed
  public_network_access_enabled = true # later: lock down with private endpoints

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = {
    environment = "chatbot"
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "chatbot_db" {
  name                = "chatbotdb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.chatbot_cosmos.name
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "chatbot_container" {
  name                = "sessions"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.chatbot_cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.chatbot_db.name

  partition_key_paths = ["/sessionId"]

  indexing_policy {
    indexing_mode = "consistent"
  }
}

# Role Assignment: allow workload identity to access Cosmos DB
resource "azurerm_role_assignment" "workload_cosmos_access" {
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  role_definition_name = "Cosmos DB Account Reader Role"
  scope                = azurerm_cosmosdb_account.chatbot_cosmos.id
}
