
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.45.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

### Group ###

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.sys}"
  location = var.location
}

### Network ###

resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "internet" {
  name                        = "rule-internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.sys}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  # delegation {
  #   name = "delegation"
  #   service_delegation {
  #     actions = [
  #       "Microsoft.Network/virtualNetworks/subnets/action",
  #     ]
  #     name = "Microsoft.Web/serverFarms"
  #   }
  # }
}

resource "azurerm_subnet" "app_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.90.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# resource "azurerm_subnet_network_security_group_association" "app_gateway" {
#   subnet_id                 = azurerm_subnet.app_gateway.id
#   network_security_group_id = azurerm_network_security_group.main.id
# }

### Web App ###

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "default" {
  name                = "appi-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "other"
}

resource "azurerm_service_plan" "main" {
  name                = "plan-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    always_on = true

    application_stack {
      docker_image     = "nginx"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.default.connection_string
    DOCKER_ENABLE_CI                      = true
    DOCKER_REGISTRY_SERVER_URL            = "https://index.docker.io"
    WEBSITES_PORT                         = "80"
  }
}

### App Service Private Endpoint ###

resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azurewebsites" {
  name                  = "azurewebsites-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = true
}


resource "azurerm_private_endpoint" "app" {
  name                = "pe-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_dns_zone_group {
    name = azurerm_private_dns_zone.azurewebsites.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.azurewebsites.id
    ]
  }

  private_service_connection {
    name                           = "azurewebsites"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

}

### App Server diagnostics ###

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name                       = "Plan Diagnostics"
  target_resource_id         = azurerm_service_plan.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      days    = 7
      enabled = true
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "Application Diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceConsoleLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceAppLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceAuditLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "AppServicePlatformLogs"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 7
      enabled = true
    }
  }
}

### Application Gateway ###

resource "azurerm_application_gateway" "main" {
  name                = "agw-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  # frontend_port {
  #   name = "https-port"
  #   port = 443
  # }

  frontend_ip_configuration {
    name      = "private-frontend"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  backend_address_pool {
    name  = "address-pool"
    fqdns = [azurerm_linux_web_app.main.default_hostname]
  }

  backend_http_settings {
    name                  = "https-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60

    pick_host_name_from_backend_address = true

    probe_name = "app-service-probe"
  }

  probe {
    name                = "app-service-probe"
    protocol            = "Https"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    pick_host_name_from_backend_http_settings = true
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "private-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # http_listener {
  #   name                           = "https-listener"
  #   frontend_ip_configuration_name = "private-frontend"
  #   frontend_port_name             = "https-port"
  #   protocol                       = "Https"
  # }

  request_routing_rule {
    name                       = "http-route"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "address-pool"
    backend_http_settings_name = "https-settings"
  }

  # request_routing_rule {
  #   name                       = "https-route"
  #   rule_type                  = "Basic"
  #   http_listener_name         = "https-listener"
  #   backend_address_pool_name  = "address-pool"
  #   backend_http_settings_name = "https-settings"
  #   priority                   = 100
  # }

}


resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name                       = "App Gateway Diagnostics"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"

    retention_policy {
      days    = 7
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 7
      enabled = true
    }
  }
}

### Virtual Machine for DNS ###

resource "azurerm_public_ip" "main" {
  name                = "pip-dns-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "nic-dns-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "dns"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-dns-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_user
  # admin_password        = var.vm_admin_password
  network_interface_ids = [azurerm_network_interface.main.id]

  custom_data = filebase64("${path.module}/init.sh")

  admin_ssh_key {
    username   = var.vm_admin_user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "22.04.202302280"
  }
}
