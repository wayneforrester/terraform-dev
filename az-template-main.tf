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


