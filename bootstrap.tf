resource "random_string" "storage_account_name" {
  length  = 5
  lower   = true
  upper   = false
  special = false
  number  = false
}

resource "azurerm_storage_account" "bootstrap" {
  name                      = "bootstrap${random_string.storage_account_name.result}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  location                  = var.resource_location
  resource_group_name       = var.resource_group_name
  depends_on                = [azurerm_resource_group.this]
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "bootstrap" {
  name                 = "bootstrap"
  storage_account_name = azurerm_storage_account.bootstrap.name
  quota                = 2
}

resource "azurerm_storage_share_directory" "vmseries" {
  for_each             = var.vmseries
  name                 = each.key
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name
}

resource "azurerm_storage_share_directory" "plugins" {
  for_each             = var.vmseries
  name                 = "${each.key}/plugins"
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name

  provisioner "local-exec" {
    command = "az storage file upload-batch --account-name ${azurerm_storage_account.bootstrap.name} --account-key ${azurerm_storage_account.bootstrap.primary_access_key} --destination ${azurerm_storage_share.bootstrap.name}/${each.key}/plugins  --source bootstrap_files/plugins"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "az storage file delete-batch --account-name ${self.storage_account_name}  --source bootstrap/${each.key}/plugins"
    on_failure = continue
  }

  depends_on = [
    azurerm_storage_share_directory.vmseries,
  ]

}

resource "azurerm_storage_share_directory" "software" {
  for_each             = var.vmseries
  name                 = "${each.key}/software"
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name

  provisioner "local-exec" {
    command = "az storage file upload-batch --account-name ${azurerm_storage_account.bootstrap.name} --account-key ${azurerm_storage_account.bootstrap.primary_access_key} --destination ${azurerm_storage_share.bootstrap.name}/${each.key}/software  --source bootstrap_files/software"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "az storage file delete-batch --account-name ${self.storage_account_name} --source bootstrap/${each.key}/software"
    on_failure = continue
  }
  depends_on = [
    azurerm_storage_share_directory.vmseries,
  ]

}

resource "azurerm_storage_share_directory" "license" {
  for_each             = var.vmseries
  name                 = "${each.key}/license"
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name

  provisioner "local-exec" {
    when       = destroy
    command    = "az storage file delete-batch --account-name ${self.storage_account_name} --source bootstrap/${each.key}/license"
    on_failure = continue
  }
  depends_on = [
    azurerm_storage_share_directory.vmseries,
    local_file.authcodes,
  ]

}

resource "azurerm_storage_share_directory" "content" {
  for_each             = var.vmseries
  name                 = "${each.key}/content"
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name

  provisioner "local-exec" {
    command = "az storage file upload-batch --account-name ${azurerm_storage_account.bootstrap.name} --account-key ${azurerm_storage_account.bootstrap.primary_access_key} --destination ${azurerm_storage_share.bootstrap.name}/${each.key}/content  --source bootstrap_files/content"
  }

  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  provisioner "local-exec" {
    when       = destroy
    command    = "az storage file delete-batch --account-name ${self.storage_account_name} --source bootstrap/${each.key}/content"
    on_failure = continue
  }
  depends_on = [
    azurerm_storage_share_directory.vmseries,
  ]

}

resource "azurerm_storage_share_directory" "config" {
  for_each             = var.vmseries
  name                 = "${each.key}/config"
  share_name           = azurerm_storage_share.bootstrap.name
  storage_account_name = azurerm_storage_account.bootstrap.name

  provisioner "local-exec" {
    command = "az storage file upload-batch --account-name ${azurerm_storage_account.bootstrap.name} --account-key ${azurerm_storage_account.bootstrap.primary_access_key} --destination ${azurerm_storage_share.bootstrap.name}/${each.key}/config  --source tmp/${each.key}/config"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "az storage file delete-batch --account-name ${self.storage_account_name} --source bootstrap/${each.key}/config"
    on_failure = continue
  }

  depends_on = [
    local_file.initcfg_txt,
    azurerm_storage_share_directory.vmseries,
  ]
}

resource "null_resource" "license" {
  for_each = var.vmseries

  provisioner "local-exec" {
    command = "az storage file upload-batch --account-name ${azurerm_storage_account.bootstrap.name} --account-key ${azurerm_storage_account.bootstrap.primary_access_key} --destination ${azurerm_storage_share.bootstrap.name}/${each.key}/license  --source tmp/${each.key}/license"
  }

  triggers = {
    always_run = each.value.authcodes
  }

  depends_on = [
    azurerm_storage_share_directory.license,
    local_file.authcodes,
    data.template_file.authcodes,
  ]
}

data "template_file" "authcodes" {
  for_each = var.vmseries
  template = file("bootstrap_files/license/authcodes.template")
  vars = {
    authcodes = each.value.authcodes
  }
}

resource "local_file" "authcodes" {
  for_each = var.vmseries
  filename = "${path.module}/tmp/${each.key}/license/authcodes"
  content  = data.template_file.authcodes[each.key].rendered
}


data "template_file" "initcfg_txt" {
  template = file("bootstrap_files/config/init-cfg.txt.template")
  vars = {
    //    panorama_server1 = var.panorama.primary
    //    panorama_server2 = var.panorama.secondary
    //    template_stack   = local.template_stack_name
    //    device_group     = local.device_group_name
    //    vm_auth_key      = var.panorama.vm_auth_key
    //    pin_id           = var.csp_pin_id
    //    pin_value        = var.csp_pin_value
  }
}

resource "local_file" "initcfg_txt" {
  for_each = var.vmseries
  filename = "${path.module}/tmp/${each.key}/config/init-cfg.txt"
  content  = data.template_file.initcfg_txt.rendered
}

data "template_file" "bootstrap_cfg_LPAZ-05433-FW-PRIM" {
  template = file("bootstrap_files/config/vmseries.xml.template")
  vars = {
    private_next_hop = cidrhost(azurerm_subnet.this["TRUST"].address_prefix, 1)
    public_next_hop = cidrhost(azurerm_subnet.this["UNTRUST"].address_prefix, 1)
    peer_management_ip = azurerm_network_interface.management["FW-SEC"].private_ip_address
    ha2_ip = azurerm_network_interface.eth1_3["FW-PRIM"].private_ip_address
    ha2_subnet = cidrnetmask(azurerm_subnet.this["HA"].address_prefix)
  }
}

data "template_file" "bootstrap_cfg_LPAZ-05433-FW-SEC" {
  template = file("bootstrap_files/config/vmseries.xml.template")
  vars = {
    private_next_hop = cidrhost(azurerm_subnet.this["TRUST"].address_prefix, 1)
    public_next_hop = cidrhost(azurerm_subnet.this["UNTRUST"].address_prefix, 1)
    peer_management_ip = azurerm_network_interface.management["FW-PRIM"].private_ip_address
    ha2_ip = azurerm_network_interface.eth1_3["FW-SEC"].private_ip_address
    ha2_subnet = cidrnetmask(azurerm_subnet.this["HA"].address_prefix)
  }
}

resource "local_file" "bootstrap_xml_LPAZ-05433-FW-PRIM" {
  for_each = var.vmseries
  filename = "${path.module}/tmp/LPAZ-05433-FW-PRIM/config/bootstrap.xml"
  content  = data.template_file.bootstrap_cfg_LPAZ-05433-FW-PRIM.rendered
}

resource "local_file" "bootstrap_xml_LPAZ-05433-FW-SEC" {
  for_each = var.vmseries
  filename = "${path.module}/tmp/LPAZ-05433-FW-SEC/config/bootstrap.xml"
  content  = data.template_file.bootstrap_cfg_LPAZ-05433-FW-SEC.rendered
}
