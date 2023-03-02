
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

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.sys}"
  location = var.location
}

# resource "azurerm_network_security_group" "example" {
#   name                = "example-security-group"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
# }

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

  lifecycle {
    ignore_changes = [
      sku_name, worker_count
    ]
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.sys}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

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

### DNS ###

resource "azurerm_network_interface" "main" {
  name                = "nic-dns-${var.sys}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "dns"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                             = "vm-dns-${var.sys}"
  location                         = azurerm_resource_group.main.location
  resource_group_name              = azurerm_resource_group.main.name
  network_interface_ids            = [azurerm_network_interface.main.id]
  vm_size                          = var.dns_vm_size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "22.04.202302280"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "privatedns"
    admin_username = var.dns_vm_username
    admin_password = var.dns_vm_password
    custom_data    = filebase64("${path.module}/init.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
