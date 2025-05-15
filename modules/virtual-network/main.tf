resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.workload}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "app_service" {
  name                 = "app-service-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "gateway" {
  name                 = "gateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "private-endpoints-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.20.0/24"]
}

resource "azurerm_subnet" "compute" {
  name                 = "compute-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.30.0/24"]
}

# resource "azurerm_network_security_group" "main" {
#   name                = "nsg-${var.workload}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_network_security_rule" "internet" {
#   name                        = "rule-internet"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = var.resource_group_name
#   network_security_group_name = azurerm_network_security_group.main.name
# }

# resource "azurerm_subnet_network_security_group_association" "main" {
#   subnet_id                 = azurerm_subnet.main.id
#   network_security_group_id = azurerm_network_security_group.main.id
# }
