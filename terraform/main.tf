provider "azurerm" {
  version = "~> 4.0"
  features {}
}

resource "azurerm_resource_group" "aks-resource-group" {
  name     = "aks-resource-group"
  location = "East US 2"
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks-resource-group.location
  resource_group_name = azurerm_resource_group.aks-resource-group.name
  dns_prefix          = "aksdns"
  

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "prod"
  }

}
## INGRESS
# resource "azurerm_virtual_network" "vnet" {
#   name                = "myVnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_subnet" "subnet" {
#   name                 = "mySubnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# resource "azurerm_public_ip" "public_ip" {
#   name                = "myPublicIP"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
# }

# resource "azurerm_application_gateway" "appgw" {
#   name                = "myAppGateway"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   sku {
#     name     = "WAF_v2"
#     tier     = "WAF_v2"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "myAppGatewayIpConfig"
#     subnet_id = azurerm_subnet.subnet.id
#   }

#   frontend_ip_configuration {
#     name                 = "myAppGatewayFrontendIpConfig"
#     public_ip_address_id = azurerm_public_ip.public_ip.id
#   }

#   frontend_port {
#     name = "frontendPort"
#     port = 80
#   }

#   backend_address_pool {
#     name = "backendAddressPool"
#   }

#   backend_http_settings {
#     name                  = "defaultBackendHttpSettings"
#     cookie_based_affinity = "Disabled"
#     port                  = 8080
#     protocol              = "Http"
#     request_timeout       = 20
#   }

#   http_listener {
#     name                           = "httpListener"
#     frontend_ip_configuration_name = "myAppGatewayFrontendIpConfig"
#     frontend_port_name             = "frontendPort"
#     protocol                       = "Http"
#   }

#   request_routing_rule {
#     name                       = "rule1"
#     rule_type                  = "Basic"
#     http_listener_name         = "httpListener"
#     backend_address_pool_name  = "backendAddressPool"
#     backend_http_settings_name = "defaultBackendHttpSettings"
#   }

#   autoscale_configuration {
#     min_capacity = 2
#   }
#}
