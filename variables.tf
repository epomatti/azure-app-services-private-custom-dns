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
  default = "B2"
}

variable "dns_vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "dns_vm_username" {
  type    = string
  default = "dnsadmin"
}

variable "dns_vm_password" {
  type      = string
  default   = "P@ssw0rd.123"
  sensitive = true
}
