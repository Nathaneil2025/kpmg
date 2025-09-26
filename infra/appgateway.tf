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

# SSL certificate stored in Key Vault (placeholder for now)
resource "azurerm_key_vault_certificate" "appgw_cert" {
  name         = "chatbot-appgw-cert"
  key_vault_id = azurerm_key_vault.chatbot_kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=chatbot-appgw"
      validity_in_months = 12
      key_usage = [
        "digitalSignature",
        "keyEncipherment"
      ]
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"] # TLS server auth
    }
  }
}

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

  frontend_ip_configuration {
    name                 = "appgw-feip"
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
    name                           = "listener-http"
    frontend_ip_configuration_name = "appgw-feip"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "listener-https"
    frontend_ip_configuration_name = "appgw-feip"
    frontend_port_name             = "port443"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-cert"
  }

  ssl_certificate {
    name                = "appgw-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.appgw_cert.secret_id
  }

request_routing_rule {
  name                       = "rule-http"
  rule_type                  = "Basic"
  http_listener_name         = "listener-http"
  backend_address_pool_name  = "default-backend-pool"
  backend_http_settings_name = "default-backend-httpsetting"
  priority                   = 100
}

  # redirect all HTTP → HTTPS
  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    include_path         = true
    include_query_string = true
    target_listener_name = "listener-https"
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
}

