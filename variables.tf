# Project
variable "subscription_id" {
  type = string
}

variable "location" {
  type = string
}

variable "my_ip_address" {
  type = string
}

# App Service
variable "app_service_sku_name" {
  type = string
}

variable "app_service_public_network_access_enabled" {
  type = bool
}

# Virtual Machine - DNS
variable "vm_size" {
  type = string
}

variable "vm_public_key_path" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "vm_image_publisher" {
  type = string
}

variable "vm_image_offer" {
  type = string
}

variable "vm_image_sku" {
  type = string
}

variable "vm_image_version" {
  type = string
}

# Applicatoin Gateway
variable "app_gateway_sku_name" {
  type = string
}

variable "app_gateway_sku_tier" {
  type = string
}

variable "app_gateway_sku_capacity" {
  type = string
}

variable "app_gateway_pfx_password" {
  type      = string
  sensitive = true
}

variable "app_gateway_private_ip_address" {
  type = string
}
