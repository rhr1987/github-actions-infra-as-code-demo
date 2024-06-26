##############################################################################################################
#
# Fortinet
# Infrastructure As Code Demo
# GitHub Actions - Terraform Cloud
# Platform: Azure
#
##############################################################################################################
#
# Deployment of the FortiGate Next-generation Firewall
#
##############################################################################################################

resource "azurerm_public_ip" "fgtpip" {
  name                = "${var.PREFIX}-fgt-pip"
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s-%s", lower(var.PREFIX), "fgt-pip")
}

resource "azurerm_network_interface" "fgtifcext" {
  name                           = "${var.PREFIX}-fgt-vm-ifc-ext"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["1"]
    public_ip_address_id          = azurerm_public_ip.fgtpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcmgmtnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcext.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}


resource "azurerm_network_interface" "fgtifcint" {
  name                           = "${var.PREFIX}-fgt-vm-ifc-int"
  location                       = azurerm_resource_group.resourcegroup.location
  resource_group_name            = azurerm_resource_group.resourcegroup.name
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = var.FGT_ACCELERATED_NETWORKING

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.fgt_ipaddress["2"]
  }
}

resource "azurerm_network_interface_security_group_association" "fgtifcintnsg" {
  network_interface_id      = azurerm_network_interface.fgtifcint.id
  network_security_group_id = azurerm_network_security_group.fgtnsg.id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  name                       = "${var.PREFIX}-fgt-vm"
  location                   = azurerm_resource_group.resourcegroup.location
  resource_group_name        = azurerm_resource_group.resourcegroup.name
  network_interface_ids      = [azurerm_network_interface.fgtifcext.id, azurerm_network_interface.fgtifcint.id]
  size                       = var.fgt_vmsize
  encryption_at_host_enabled = false
  secure_boot_enabled        = false
  vtpm_enabled               = false

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.FGT_IMAGE_SKU
    version   = var.FGT_VERSION
  }

  plan {
    name      = var.FGT_IMAGE_SKU
    product   = "fortinet_fortigate-vm_v5"
    publisher = "fortinet"
  }

  os_disk {
    name                 = "${var.PREFIX}-fgt-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  admin_username                  = var.USERNAME
  admin_password                  = var.PASSWORD
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/customdata-fgt.tpl", {
    fgt_vm_name           = "${var.PREFIX}-FGT-VM",
    fgt_license_file      = var.FGT_BYOL_LICENSE_FILE,
    fgt_license_fortiflex = fortiflexvm_entitlements_vm_token.fortiflex_vm.token
    fgt_username          = var.USERNAME,
    fgt_password          = var.PASSWORD,
    fgt_ssh_public_key    = var.FGT_SSH_PUBLIC_KEY_FILE,
    fgt_external_ipaddr   = var.fgt_ipaddress["1"],
    fgt_external_mask     = var.subnetmask["1"],
    fgt_external_gw       = var.gateway_ipaddress["1"],
    fgt_internal_ipaddr   = var.fgt_ipaddress["2"],
    fgt_internal_mask     = var.subnetmask["2"],
    fgt_internal_gw       = var.gateway_ipaddress["2"],
    vnet_network          = var.vnet
  }))

  boot_diagnostics {
  }

  tags = var.fortinet_tags

  lifecycle {
    ignore_changes = [custom_data]
  }
}

data "azurerm_public_ip" "fgtpip" {
  name                = azurerm_public_ip.fgtpip.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  depends_on          = [azurerm_linux_virtual_machine.fgtvm]
}

##############################################################################################################
# Role Assignment for Managed Identity
##############################################################################################################

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "rolerg" {
  scope                = azurerm_resource_group.resourcegroup.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.fgtvm.identity[0].principal_id
}

resource "azurerm_role_assignment" "rolesub" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.fgtvm.identity[0].principal_id
}
