# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "rsgroup" {
    name     = "VMResourceGroup"
    location = "${var.azure_region}"

    tags = {
        environment = "VM Creation"
    }
}

#Adding the user to Ubuntu VM.
locals {
  custom_data = <<CUSTOM_DATA
  #!/bin/bash
  echo "Execute your super awesome commands here!"
  adduser --gecos "" ubuntuusradm
  echo thePassword | passwd ubuntuusradm --stdin
  CUSTOM_DATA
  }
  
  
# Random password generation
resource "random_password" "admin_password" {
  special = false
  length  = 8
}

# Create virtual network
resource "azurerm_virtual_network" "AZVnet" {
    name                = "VMVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.azure_region}"
    resource_group_name = azurerm_resource_group.rsgroup.name

    tags = {
        environment = "VM Creation"
    }
}

# Create subnet
resource "azurerm_subnet" "AZsubnet" {
    name                 = "VNETSubnet"
    resource_group_name  = azurerm_resource_group.rsgroup.name
    virtual_network_name = azurerm_virtual_network.AZVnet.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "VMPublicIIP" {
    count                        = "${var.no_vm}"
    name                         = "PublicIP${count.index}"
    location                     = "${var.azure_region}"
    resource_group_name          = azurerm_resource_group.rsgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "VM Creation"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "aznsg" {
    name                = "NSG"
    location            = "${var.azure_region}"
    resource_group_name = azurerm_resource_group.rsgroup.name

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

    tags = {
        environment = "VM Creation"
    }
}

# Create network interface
resource "azurerm_network_interface" "aznic" {
    count                     = "${var.no_vm}"
    name                      = "NIC${count.index}"
    location                  = "${var.azure_region}"
    resource_group_name       = azurerm_resource_group.rsgroup.name

    ip_configuration {
        name                          = "NicConfiguration${count.index}"
        subnet_id                     = azurerm_subnet.AZsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.VMPublicIIP[count.index].id}"
    }

    tags = {
        environment = "VM Creation"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "azssgassociation" {
    count                 = "${var.no_vm}"
    network_interface_id      = "${azurerm_network_interface.aznic[count.index]}"
    network_security_group_id = azurerm_network_security_group.aznsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        resource_group = azurerm_resource_group.rsgroup.name
    }
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "VMStroageAccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rsgroup.name
    location                    = "${var.azure_region}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "VM Creation"
    }
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "azvmlinux" {
    count                 = "${var.no_vm}"
    name                  = "AZVM${count.index}"
    location              = "${var.azure_region}"
    resource_group_name   = azurerm_resource_group.rsgroup.name
    network_interface_ids = [element(azurerm_network_interface.aznic.*.id, count.index)]
    size                  = "${var.size}"

    os_disk {
        name              = "VMOsDisk${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "${var.linux_flavors}"
        sku       = "${var.linux_flavors_sku}"
        version   = "latest"
    }

    computer_name  = "azvminstance"
    admin_username = "azureuser"
	admin_password = "${random_password.admin_password.result}"
    disable_password_authentication = false
    custom_data = base64encode(local.custom_data)

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.VMStroageAccount.primary_blob_endpoint
    }

    tags = {
        environment = "VM Creation"
    }
}

#UbuntuServer, WindowsServer
#admin_password
#vm_size