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
    name     = "az104-vm-rg"
    location = "eastus"
    tags = {
      environment = "Terraform Dev"
      costCenter  = "az104"
    }
}

# Create nsg
resource "azurerm_network_security_group" "nsg" {
  name                = "az104-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDPInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "az104-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

    tags = {
      environment = "Terraform Dev"
      costCenter  = "az104"
    }
}

# create subnet1
resource "azurerm_subnet" "subnet1" {
  name = "az104-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# create public IP for win vm
resource "azurerm_public_ip" "winvmpublicip" {
  name                = "pip-windows-vm-publicip-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Dev"
    costCenter  = "az104"
  }
}

# Assosciate NSG to subnet1
resource "azurerm_subnet_network_security_group_association" "subnet1tonsg" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# linux vm nic
resource "azurerm_network_interface" "linuxvmnic" {
  name                = "linux-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Terraform Dev"
    costCenter  = "az104"
  }
}

# windows vm nic
resource "azurerm_network_interface" "winvmnic" {
  name                = "windows-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.winvmpublicip.id
  }

    tags = {
      environment = "Terraform Dev"
      costCenter  = "az104"
    }
}

# linux vm
resource "azurerm_linux_virtual_machine" "linuxvm" {
  name                = "az104-linux-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.linuxvmnic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

    tags = {
      environment = "Terraform Dev"
      costCenter  = "az104"
    }
}

# windows vm
resource "azurerm_windows_virtual_machine" "winvm" {
  name                = "az104-win-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.winvmnic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

    tags = {
      environment = "Terraform Dev"
      costCenter  = "az104"
    }
}

output "vm_public_ip" {
  value = azurerm_public_ip.winvmpublicip.ip_address
}