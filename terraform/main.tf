resource "azurerm_resource_group" "pfa" {
  name     = "PFServer"
  location = "westeurope"
}

resource "azurerm_virtual_network" "mynetwork" {
  name                = "my-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.pfa.location
  resource_group_name = azurerm_resource_group.pfa.name
}

resource "azurerm_subnet" "mysubnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.pfa.name
  virtual_network_name = azurerm_virtual_network.mynetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "mypublicip" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.pfa.location
  resource_group_name = azurerm_resource_group.pfa.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "pfa" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.pfa.location
  resource_group_name = azurerm_resource_group.pfa.name

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "server"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "client"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "mynic" {
  name                = "my-nic"
  location            = azurerm_resource_group.pfa.location
  resource_group_name = azurerm_resource_group.pfa.name

  ip_configuration {
    name                          = "my-nic-ip"
    subnet_id                     = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.mynic.id
  network_security_group_id = azurerm_network_security_group.pfa.id
}

resource "azurerm_linux_virtual_machine" "myvm" {
  name                  = "my-vm"
  location              = azurerm_resource_group.pfa.location
  resource_group_name   = azurerm_resource_group.pfa.name
  size                  = "Standard_B1s"
  admin_username        = "Hamza"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.mynic.id]

  admin_ssh_key {
    username   = "Hamza"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx0qC48ymjly7FgKHzO55rLp9EciHe4ZSFSx0uic/FRMnwq4VcrWYaL0cD8as797UrPi2Vdm+8uena7dn0LYmmktw5Z0c2hTnO8u8HyofEY3UONbDAQP+qOwRT0FmKLefGG9FjXeywVfOZdWxjjQKxiGKGpgxIOnOH+de0YCbI3hCoReqTIjLxCy+XLP/RFj/hujc6chsNzdWKf3Nj0epX5Kd7MYXlgYOn4XAH40UEN3+8Tb12ttJsqV/O/CWDBdWeHpJ7C0smpcvr3bMVhzY1oH7ItK32ILkXXDZQaB/KDTuM+hG3rdKZMg5MebDMiFGxwy2zQZyj7yAHvT6lE0mSzXfe7TLKNSE5SmtVzAPzjIonFee6kWt97MZY3djbUCsIeSqndL0BU6S6ZAk/LNmsIAcKRsQO61jOzSkbGwTPzvPExNdGtdb9n/RJwZ+NGItHfIuk68Snht+y5jwCAlkRJ3plGssURcP2/IZMWxvIVAhpvEJkEPOzIyp4eoe47Q8= sampc@DESKTOP-1SGP0D1"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo docker run -ti -d -p 3000:3000 -e REACT_APP_API_URL=http://${azurerm_public_ip.mypublicip.ip_address}:8000 shintaix/clientside:latest",
      "sleep 7",  # Add a 5-second sleep here
      "sudo docker run -ti -d -p 8000:8000 shintaix/serverside:latest"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = "Hamza"
      private_key = file("${var.key}")
    }
  }
}

output "public_ip" {
  value = azurerm_public_ip.mypublicip.ip_address
}
