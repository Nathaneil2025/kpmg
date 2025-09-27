resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "chatbot-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "chatbot"
  }
}

# SIMPLIFIED Application Gateway - Let AGIC manage most configuration
resource "azurerm_application_gateway" "chatbot_appgw" {
  name                = "chatbot-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_identity.id]
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  # PRIVATE Frontend IP (for internal VNet access from API Management)
  frontend_ip_configuration {
    name                          = "appgw-feip-private"
    subnet_id                     = azurerm_subnet.appgw_subnet.id
    private_ip_address            = "192.168.3.10"
    private_ip_address_allocation = "Static"
  }

  # PUBLIC Frontend IP (required for WAF_v2)
  frontend_ip_configuration {
    name                 = "appgw-feip-public"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }

  frontend_port {
    name = "port80"
    port = 80
  }

  frontend_port {
    name = "port443"
    port = 443
  }

  # MINIMAL required configuration - AGIC will manage the rest
  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "default-backend-httpsetting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "default-listener"
    frontend_ip_configuration_name = "appgw-feip-private"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-backend-httpsetting"
    priority                   = 1
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  tags = {
    environment = "chatbot"
  }

  lifecycle {
    # Ignore changes that AGIC will manage
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      probe,
      redirect_configuration,
      url_path_map
    ]
  }
}