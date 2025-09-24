# -----------------------------------------
# Log Analytics Workspace
# -----------------------------------------
resource "azurerm_log_analytics_workspace" "chatbot_logs" {
  name                = "chatbot-law-2025"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "chatbot"
  }
}

# -----------------------------------------
# Diagnostic Settings
# -----------------------------------------

# AKS diagnostics
resource "azurerm_monitor_diagnostic_setting" "acr_diagnostics" {
  name                       = "acr-diagnostics"
  target_resource_id         = data.azurerm_container_registry.chatbot_acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
  }
}

# Cosmos DB diagnostics
resource "azurerm_monitor_diagnostic_setting" "cosmos_diagnostics" {
  name                       = "cosmos-diagnostics"
  target_resource_id         = azurerm_cosmosdb_account.chatbot_cosmos.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "DataPlaneRequests"
  }

  metric {
    category = "AllMetrics"
  }
}

# Redis diagnostics
resource "azurerm_monitor_diagnostic_setting" "redis_diagnostics" {
  name                       = "redis-diagnostics"
  target_resource_id         = azurerm_redis_cache.chatbot_redis.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "ConnectedClientList"
  }

  metric {
    category = "AllMetrics"
  }
}

# ACR diagnostics
resource "azurerm_monitor_diagnostic_setting" "acr_diagnostics" {
  name                       = "acr-diagnostics"
  target_resource_id         = azurerm_container_registry.chatbot_acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  metric {
    category = "AllMetrics"
  }
}

# APIM diagnostics
resource "azurerm_monitor_diagnostic_setting" "apim_diagnostics" {
  name                       = "apim-diagnostics"
  target_resource_id         = azurerm_api_management.chatbot_apim.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "GatewayLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Application Gateway diagnostics
resource "azurerm_monitor_diagnostic_setting" "appgw_diagnostics" {
  name                       = "appgw-diagnostics"
  target_resource_id         = azurerm_application_gateway.chatbot_appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Front Door diagnostics
resource "azurerm_monitor_diagnostic_setting" "frontdoor_diagnostics" {
  name                       = "frontdoor-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.chatbot_fd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.chatbot_logs.id

  enabled_log {
    category = "FrontdoorAccessLog"
  }

  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}
