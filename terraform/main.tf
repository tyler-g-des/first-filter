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

resource "azurerm_resource_group" "aks-resource-group" {
  name     = "aks-resource-group"
  location = "East US 2"
}

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