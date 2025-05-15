terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

resource "random_string" "affix" {
  numeric     = true
  length      = 3
  min_numeric = 3
}

locals {
  workload = "contoso${random_string.affix.result}"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.workload}"
  location = var.location
}

module "virtual_network" {
  source              = "./modules/virtual-network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workload            = local.workload
}

module "monitor" {
  source              = "./modules/monitor"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workload            = local.workload
}

module "app_service" {
  source                        = "./modules/app-service"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  workload                      = local.workload
  sku_name                      = var.app_service_sku_name
  log_analytics_workspace_id    = module.monitor.log_analytics_workspace_id
  subnet_id                     = module.virtual_network.app_service_subnet_id
  public_network_access_enabled = var.app_service_public_network_access_enabled
}

module "private_endpoints" {
  source                      = "./modules/private-endpoints"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  workload                    = local.workload
  vnet_id                     = module.virtual_network.vnet_id
  private_endpoints_subnet_id = module.virtual_network.private_endpoints_subnet_id
  app_service_id              = module.app_service.app_service_id
}

module "application_gateway" {
  source                         = "./modules/application-gateway"
  resource_group_name            = azurerm_resource_group.main.name
  location                       = azurerm_resource_group.main.location
  workload                       = local.workload
  subnet_id                      = module.virtual_network.gateway_subnet_id
  app_gateway_private_ip_address = var.app_gateway_private_ip_address
  app_service_default_hostname   = module.app_service.default_hostname
  app_gateway_sku_capacity       = var.app_gateway_sku_capacity
  app_gateway_sku_name           = var.app_gateway_sku_name
  app_gateway_sku_tier           = var.app_gateway_sku_tier
  app_gateway_pfx_password       = var.app_gateway_pfx_password
  log_analytics_workspace_id     = module.monitor.log_analytics_workspace_id
}

module "virtual_machine" {
  source              = "./modules/virtual-machines/dns"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workload            = local.workload
  vm_size             = var.vm_size
  subnet_id           = module.virtual_network.compute_subnet_id
  vm_public_key_path  = var.vm_public_key_path
  vm_admin_username   = var.vm_admin_username
  vm_image_publisher  = var.vm_image_publisher
  vm_image_offer      = var.vm_image_offer
  vm_image_sku        = var.vm_image_sku
  vm_image_version    = var.vm_image_version
}
