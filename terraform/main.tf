 terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
	}
}


provider "azurerm" {
  features {}
}

# resource "azurerm_resource_group" "aks-resource-group" {
#   name     = "aks-resource-group"
#   location = "East US 2"
# }

# resource "azurerm_app_service_plan" "aks-resource-group" {
#   name                = "__appserviceplan__"
#   location            = "${azurerm_resource_group.aks-resource-group.location}"
#   resource_group_name = "${azurerm_resource_group.aks-resource-group.name}"

#   sku {
#     tier = "Free"
#     size = "F1"
#   }
# }

# resource "azurerm_app_service" "aks-resource-group" {
#   name                = "__appservicename__"
#   location            = "${azurerm_resource_group.aks-resource-group.location}"
#   resource_group_name = "${azurerm_resource_group.aks-resource-group.name}"
#   app_service_plan_id = "${azurerm_app_service_plan.aks-resource-group.id}"

# }

resource "azurerm_virtual_network" "vnet" {
  name                = "app-service-vnet"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "app-service-subnet"
  resource_group_name  = azurerm_resource_group.aks_resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "__appserviceplan__"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "app_service" {
  name                = "__appservicename__"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id

  site_config {
    linux_fx_version = "NODE|14-lts"  # Utiliza Node.js para el proxy
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "14-lts"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "app_service_vnet" {
  app_service_id = azurerm_app_service.app_service.id
  subnet_id      = azurerm_subnet.subnet.id
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