resource "azurerm_service_plan" "main" {
  name                = "plan-${var.workload}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "main" {
  name                          = "app-${var.workload}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.main.id
  https_only                    = true
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.subnet_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on     = true
    http2_enabled = true

    health_check_path                 = "/"
    health_check_eviction_time_in_min = 3

    application_stack {
      docker_image_name   = "nginx:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    # APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.default.connection_string
    DOCKER_ENABLE_CI = true
    WEBSITES_PORT    = "80"
  }
}

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name                       = "Plan Diagnostics"
  target_resource_id         = azurerm_service_plan.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "Application Diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
