# Project
subscription_id = "000-0000-0000-0000-000000000000"
location        = "brazilsouth"
my_ip_address   = "1.2.4.4"

# App Service
app_service_sku_name                      = "B1"
app_service_public_network_access_enabled = false

# Virtual Machine - DNS
vm_public_key_path = ".keys/tmp_rsa.pub"
vm_admin_username  = "azureuser"
vm_size            = "Standard_B2ls_v2"
vm_image_publisher = "canonical"
vm_image_offer     = "ubuntu-24_04-lts"
vm_image_sku       = "server"
vm_image_version   = "latest"

# Application Gateway
app_gateway_pfx_password       = "p4ssw0rd"
app_gateway_sku_name           = "Standard_v2"
app_gateway_sku_tier           = "Standard_v2"
app_gateway_sku_capacity       = 1
app_gateway_private_ip_address = "10.0.10.100"
