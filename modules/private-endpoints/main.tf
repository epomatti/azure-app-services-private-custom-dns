resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azurewebsites" {
  name                  = "azurewebsites-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = true
}


resource "azurerm_private_endpoint" "app" {
  name                = "pe-${var.workload}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id

  private_dns_zone_group {
    name = azurerm_private_dns_zone.azurewebsites.name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.azurewebsites.id
    ]
  }

  private_service_connection {
    name                           = "azurewebsites"
    private_connection_resource_id = var.app_service_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}
