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
    # Remove version as this is now deprecated in the provider block
    # version = "1.38.0"
}

# Create resource group
resource "azurerm_resource_group" "rg" {
    name     = "rg-TerraformDev"
    location = "westus2"
    tags = {
      "Environment" = "Terraform Dev"
    }
}

# Create a vnet
resource "azurerm_virtual_network" "vnet" {
    name                = "vnet-dev-westus2-001"
    address_space       = [ "10.0.0.0/16" ]
    location            = "westus2"
    resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "snet-dev-westus2-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.0.0/24" ]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "pip-vmterraform-dev-westus2-001"
  location            = "westus2"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create network security group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-sshallow-001 "
  location            = "westus2"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "nic-01-vmterraform-dev-001"
  location                  = "westus2"
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "niccfg-vmterraform"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Associate NSG -> Subnet 
resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "vmterraform"
  location              = "westus2"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "stvmpmvmterraformos"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vmterraform"
    admin_username = "terrauser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Output public IP Address
output "vm_public_ip" {
  value = azurerm_public_ip.publicip.ip_address
}
