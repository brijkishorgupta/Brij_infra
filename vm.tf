resource "azurerm_resource_group" "rg" {
  name     = "depends-rg"
  location = "central india"
}

#implicit dependency
resource "azurerm_virtual_network" "vnet" {
  name                = "depends-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#explicit dependency
resource "azurerm_subnet" "subnet" {
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.rg]
  name                 = "depends-subnet"
  resource_group_name  = "depends-rg"
  virtual_network_name = "depends-vnet"
  address_prefixes     = ["10.0.2.0/24"]
}
#implicit dependency
resource "azurerm_public_ip" "pip" {
  name                = "depends-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}
#explicit dependency
resource "azurerm_network_interface" "nic" {
  depends_on = [ azurerm_resource_group.rg, azurerm_subnet.subnet, azurerm_public_ip.pip ]
  name                = "depends-nic"
  location            = "central india"
  resource_group_name = "depends-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id

  }
}
#explicit dependency
resource "azurerm_linux_virtual_machine" "vn" {
  depends_on          = [azurerm_network_interface.nic, azurerm_resource_group.rg, azurerm_subnet.subnet, azurerm_virtual_network.vnet, azurerm_public_ip.pip]
  name                = "depends-vm"
  resource_group_name = "depends-rg"
  location            = "central india"
  size                = "Standard_D2s_v5"
  admin_username      = "adminbrij"
  admin_password      = "Brij@12345678"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # admin_ssh_key {
  #   username   = "adminuser"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}