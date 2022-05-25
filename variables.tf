# ---------------------------------------------------------------------------------------------------------------------
#   Constants
# ---------------------------------------------------------------------------------------------------------------------

variable "loc_marker" {
  description = "This is the location marker prefix"
  #LifePoint/PMDS marker is LPAZ
  default = "LPAZ"
}

variable "coid" {
  description = "This is the cost center prefix"
  #COID For IT Shared Services is 05433
  default = "05433"
}


variable "tenant_id" {
  description = "This is the tenant ID to use"
  #PMDS Tenant ID is ac86c0fb-9595-416e-98dd-866098275f76
  default = "ac86c0fb-9595-416e-98dd-866098275f76"
}

variable "sub_id" {
  description = "This is the subscription ID to use"
  #PMDS IT Shared Services Subscription ID is 2262631f-5ce5-44f2-b70d-77e923b781e4
  #PMDS ProductivMD Subscription ID is 6764a8a8-1dae-457b-aacf-6396fcbb48d8
  default = "2262631f-5ce5-44f2-b70d-77e923b781e4"
}

# ---------------------------------------------------------------------------------------------------------------------
#   Resource Group
# ---------------------------------------------------------------------------------------------------------------------

variable "create_resource_group" {
  description = "Do you want the Terraform to Create the Resource Group (true) or use an Existing Resource Group (false)"
  default     = true
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  default     = "05433-Core-Network-RG"
}

# ---------------------------------------------------------------------------------------------------------------------
#   Resource Location
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_location" {
  description = "Location of all resources to be created"
  default     = "centralus"
}

# ---------------------------------------------------------------------------------------------------------------------
#   Virtual Network
# ---------------------------------------------------------------------------------------------------------------------

variable "create_virtual_network" {
  description = "Terraform to create Virtual Network (true) or use an existing Virtual Networks (false)"
  default     = true
}

variable "virtual_network_name" {
  description = "Name of the Azure Virtual Network"
  default     = "LPAZ-05433-VNET-HUB"
}

variable "virtual_network_cidr" {
  description = "Virtual Networks CIDR Block"
  default     = "10.172.64.0/24"
}

# ---------------------------------------------------------------------------------------------------------------------
#   Subnets
# ---------------------------------------------------------------------------------------------------------------------

variable "create_virtual_network_subnets" {
  description = "Terraform to create Virtual Network subnets (true) or use existing subnets (false)"
  default     = true
}

variable "virtual_network_subnets" {
  description = "Subnet Map for Creation"
  default = {
    MGMT = {
      address_prefixes = ["10.172.64.0/28"]
    },
    HA = {
      address_prefixes = ["10.172.64.16/28"]
    },
    TRUST = {
      address_prefixes = ["10.172.64.32/28"]
    },
    UNTRUST = {
      address_prefixes = ["10.172.64.48/28"]
    },
    LB = {
      address_prefixes = ["10.172.64.64/28"]
    }
  }
}

# Ensure you keep them names vmseries0 and vmseries1 or you will have to change reference in the TF files.
variable "vmseries" {
  description = "Definition of the VM-Series deployments"
  default = {
    FW-PRIM = {
      admin_username    = "pandemo"
      admin_password    = "Pal0Alto!"
      instance_size     = "Standard_DS3_v2"
      # License options "byol", "bundle1", "bundle2"
      license           = "byol"
      version           = "10.1.4-h4"
      management_ip     = "10.172.64.4"
      ha2_ip            = "10.172.64.20"
      private_ip        = "10.172.64.36"
      public_ip         = "10.172.64.52"
      availability_zone = 2
      # If not licensing authcode is needed leave this set to a value of a space (ie " ")
      authcodes = " "
    }
    FW-SEC = {
      admin_username    = "pandemo"
      admin_password    = "Pal0Alto!"
      instance_size     = "Standard_DS3_v2"
      # License options "byol", "bundle1", "bundle2"
      license           = "byol"
      version           = "10.1.4-h4"
      management_ip     = "10.172.64.5"
      ha2_ip            = "10.172.64.21"
      private_ip        = "10.172.64.37"
      public_ip         = "10.172.64.53"
      availability_zone = 2
      # If not licensing authcode is needed leave this set to a value of a space (ie " ")
      authcodes = " "
    }
  }
}


variable "inbound_tcp_ports" {
  default = [443,]
}

variable "inbound_udp_ports" {
  default = [4501,]
}