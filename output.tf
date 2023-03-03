output "dns_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "ssh_session_command" {
  value = "ssh ${azurerm_linux_virtual_machine.main.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "app_service_fqdn" {
  value = azurerm_linux_web_app.main.default_hostname  
}
