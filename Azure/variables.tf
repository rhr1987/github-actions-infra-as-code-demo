##############################################################################################################
#
# Fortinet
# Infrastructure As Code Demo
# GitHub Actions - Terraform Cloud
# Platform: Azure
#
##############################################################################################################
#
# Variables during deployment the first 4 (PREFIX, LOCATION, USERNAME, PASSWORD) are mandatory
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
  default     = "github-actions-demo"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "USERNAME" {
}

variable "PASSWORD" {
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

variable "FGT_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_20190624') or byol (Bring your own license 'fortinet_fg-vm')"
  default     = "fortinet_fg-vm"
}

variable "FGT_VERSION" {
  description = "FortiGate version by default the 'latest' available version in the Azure Marketplace is selected"
  default     = "latest"
}

variable "FGT_BYOL_LICENSE_FILE" {
  default = ""
}

variable "FGT_BYOL_FORTIFLEX_LICENSE_FILE" {
  default = ""
}

variable "FGT_SSH_PUBLIC_KEY_FILE" {
  default = ""
}

##############################################################################################################
# FortiFlex
##############################################################################################################

variable "FORTIFLEX_USERNAME" {
  description = "FORTIFLEX API username"
}

variable "FORTIFLEX_PASSWORD" {
  description = "FORTIFLEX API password"
}

variable "FORTIFLEX_CONFIG_ID" {
  description = "FORTIFLEX Config ID"
}

variable "FORTIFLEX_VM_SERIAL" {
  description = "FORTIFLEX Program Serial"
}

##############################################################################################################
# Accelerated Networking
# Only supported on specific VM series and CPU count: D/DSv2, D/DSv3, E/ESv3, F/FS, FSv2, and Ms/Mms
# https://azure.microsoft.com/en-us/blog/maximize-your-vm-s-performance-with-accelerated-networking-now-generally-available-for-both-windows-and-linux/
##############################################################################################################
variable "FGT_ACCELERATED_NETWORKING" {
  description = "Enables Accelerated Networking for the network interfaces of the FortiGate"
  default     = "true"
}

##############################################################################################################
# Accept the Terms license for the FortiGate Marketplace image
# This is a one-time agreement that needs to be accepted per subscription
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement
##############################################################################################################
#resource "azurerm_marketplace_agreement" "fortinet" {
#  publisher = "fortinet"
#  offer     = "fortinet_fortigate-vm_v5"
#  plan      = var.FGT_IMAGE_SKU
#}

##############################################################################################################
# Static variables
##############################################################################################################

variable "vnet" {
  description = ""
  default     = "172.16.136.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.0/26"  # External
    "2" = "172.16.136.64/26" # Internal
    "3" = "172.16.137.0/24"  # Protected a
    "4" = "172.16.138.0/24"  # Protected b
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "1" = "26" # External
    "2" = "26" # Internal
    "3" = "24" # Protected a
    "4" = "24" # Protected b
  }
}

variable "fgt_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.5"  # External
    "2" = "172.16.136.69" # Internal
  }
}

variable "gateway_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.136.1"  # External
    "2" = "172.16.136.65" # Internal
  }
}

variable "fgt_vmsize" {
  default = "Standard_F2s"
}

variable "fortinet_tags" {
  type = map(string)
  default = {
    publisher : "Fortinet",
    template : "GitHub Actions Infra As Code Demo Azure",
    environment : "staging"
    Name : "Robert Rother"
    Username : "rrother"
    ExpectedUseThrough : "2024-08"
    VMState : "AlwaysOn"
    CostCenter : "5900"
  }
}

variable "backend_tags" {
  type = map(string)
  default = {
    template : "GitHub Actions Infra As Code Demo Azure",
    environment : "staging",
    type : "websrv",
  }
}

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-rg"
  location = var.LOCATION
  tags     = var.fortinet_tags
}
