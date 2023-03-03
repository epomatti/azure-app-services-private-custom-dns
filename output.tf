output "dns_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "ssh_session_command" {
  value = "ssh ${azurerm_linux_virtual_machine.main.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "lb_private_ip" {
  value = azurerm_lb.main.private_ip_address
}
