output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "app_service_subnet_id" {
  value = azurerm_subnet.app_service.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "compute_subnet_id" {
  value = azurerm_subnet.compute.id
}
