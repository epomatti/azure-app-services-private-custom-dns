variable "location" {
  type    = string
  default = "eastus"
}

variable "sys" {
  type    = string
  default = "myprivateapp"
}

variable "sku_name" {
  type    = string
  default = "B1"
}

variable "vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "vm_admin_user" {
  type    = string
  default = "adminuser"
}

variable "app_gateway_private_ip" {
  type    = string
  default = "10.0.90.100"
}

# variable "vm_admin_password" {
#   type      = string
#   default   = "P@ssw0rd.123"
#   sensitive = true
# }
