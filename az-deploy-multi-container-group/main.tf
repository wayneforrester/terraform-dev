# Configure the Az provider
terraform {
  required_providers {
      azurerm = {
          source = "hashicorp/azurerm"
          version = ">= 2.26"
      }
  }
}

provider "azurerm" {
    features {}
}

# Create resource group
resource "azurerm_resource_group" "rg" {
    name     = "myResourceGroup"
    location = "eastus"
    tags = {
      environment = "Terraform Dev"
    }
}

# Create multi-container group with 2 containers
resource "azurerm_container_group" "cg" {
  name                = "myContainerGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "public"
  os_type             = "Linux"

  container {
    name   = "aci-tutorial-app"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    ports {
      port     = 8080
      protocol = "TCP"
    }
  }

  container {
    name   = "aci-tutorial-sidecar"
    image  = "mcr.microsoft.com/azuredocs/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.0"
  }

  tags = {
    environment = "Terraform Dev"
  }
}