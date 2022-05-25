

# Creation of the following resources:
#   - Azure Public IPs (Management)
# This is commented out as we don't want a public IP for management (bad practice)
# Public IP Address:
resource "azurerm_public_ip" "management" {
  for_each            = var.vmseries
  name                = "${var.loc_marker}-${var.coid}-${each.key}-MGMT_PIP00"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.this]
  sku                 = "Standard"
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Management Interface
#----------------------------------------------------------------------------------------------------------------------

# Network Interface:
resource "azurerm_network_interface" "management" {
  for_each             = var.vmseries
  name                 = "${var.loc_marker}-${var.coid}-${each.key}-MGMT_NIC00"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.this["MGMT"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.management_ip
    public_ip_address_id          = azurerm_public_ip.management[each.key].id
  }
  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_network_security_group" "management" {
  for_each            = var.vmseries
  name                = "${var.loc_marker}-${var.coid}-NSG-${each.key}_MGMT00"
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "management-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "22"]
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.this]
}

# Network Security Group (Management)
resource "azurerm_network_interface_security_group_association" "management" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.management[each.key].id
  network_security_group_id = azurerm_network_security_group.management[each.key].id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - eth1_1 Interface (Untrust)
#----------------------------------------------------------------------------------------------------------------------

# Public IP Address
resource "azurerm_public_ip" "eth1_1" {
  for_each            = var.vmseries
  name                = "${var.loc_marker}-${var.coid}-${each.key}-PIP00"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.this]
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "eth1_1" {
  for_each             = var.vmseries
  name                 = "${var.loc_marker}-${var.coid}-${each.key}-UNTRUST_NIC00"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.this["UNTRUST"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.public_ip
    public_ip_address_id          = azurerm_public_ip.eth1_1[each.key].id
  }
  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_network_security_group" "data" {
  for_each            = var.vmseries
  name                = "${var.loc_marker}-${var.coid}-NSG-${each.key}_DATA00"
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "data-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.this]

}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "eth1_1" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.eth1_1[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - eth1_2 Interface (Trust)
#----------------------------------------------------------------------------------------------------------------------

# Network Interface
resource "azurerm_network_interface" "eth1_2" {
  for_each             = var.vmseries
  name                 = "${var.loc_marker}-${var.coid}-${each.key}-TRUST_NIC00"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true
  enable_accelerated_networking = true


  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.this["TRUST"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
  }
  depends_on = [azurerm_resource_group.this]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "eth1_2" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.eth1_2[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - eth1_3 Interface (HA2)
#----------------------------------------------------------------------------------------------------------------------

# Network Interface
resource "azurerm_network_interface" "eth1_3" {
  for_each             = var.vmseries
  name                 = "${var.loc_marker}-${var.coid}-${each.key}-HA_NIC00"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.this["HA"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ha2_ip
  }
  depends_on = [azurerm_resource_group.this]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "eth1_3" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.eth1_3[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Virtual Machine
#----------------------------------------------------------------------------------------------------------------------
### *****NOTE***** - You will have to run the below command to be able to accept the license agreement and deploy the VM!
### ************** - Make sure to change the subscription to the name of the one you want to deploy the VM's in!
### ************** - THIS HAS TO BE DONE BEFORE DOING YOUR terraform apply!
### **************************************************************************************************************************
### az vm image terms accept --publisher paloaltonetworks --offer vmseries-flex --plan byol --subscription "ITS Shared Services"

resource "azurerm_linux_virtual_machine" "vmseries" {
  for_each = var.vmseries

  # Resource Group & Location:
  resource_group_name = var.resource_group_name
  location            = var.resource_location

  name = "${var.loc_marker}-${var.coid}-${each.key}"

  # Availabilty Zone:
  zone = each.value.availability_zone

  # Instance
  size = each.value.instance_size

  # Username and Password Authentication:
  disable_password_authentication = false
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password

  # Network Interfaces:
  network_interface_ids = [
    azurerm_network_interface.management[each.key].id,
    azurerm_network_interface.eth1_1[each.key].id,
    azurerm_network_interface.eth1_2[each.key].id,
    azurerm_network_interface.eth1_3[each.key].id,
  ]

  plan {
    name      = each.value.license
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = each.value.license
    version   = each.value.version
  }

  os_disk {
    name                 = "${var.loc_marker}-${var.coid}-${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Bootstrap Information for Azure:
  custom_data = base64encode(join(
    ",",
    [
      "storage-account=${azurerm_storage_account.bootstrap.name}",
      "access-key=${azurerm_storage_account.bootstrap.primary_access_key}",
      "file-share=${azurerm_storage_share.bootstrap.name}",
      "share-directory=${each.key}",
    ],
  ))

  # Dependencies:
  depends_on = [
    azurerm_network_interface.eth1_2,
    azurerm_network_interface.eth1_1,
    azurerm_network_interface.management,
  ]
}

output "LPAZ-05433-FW-PRIM_management_ip" {
  value = azurerm_public_ip.management["FW-PRIM"].ip_address
}

output "LPAZ-05433-FW-SEC_management_ip" {
  value = azurerm_public_ip.management["FW-SEC"].ip_address
}
