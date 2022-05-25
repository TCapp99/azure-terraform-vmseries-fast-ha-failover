### Create public IP for Palo ###
resource "azurerm_public_ip" "PaloExt" {
  name                = "${var.loc_marker}-${var.coid}-LB-FW_UNTRUST-PIP00"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.this]
  sku                 = "Standard"
}

### Create External LB for Palo ###
resource "azurerm_lb" "PaloExt" {
  resource_group_name = var.resource_group_name
  location            = var.resource_location
  name                = "${var.loc_marker}-${var.coid}-LB-FW_UNTRUST"
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PaloLB_PubIP00"
    public_ip_address_id = azurerm_public_ip.PaloExt.id
  }
  depends_on = [azurerm_virtual_network.this]
}

### Create Backend Pool for Palo Ext LB ###
resource "azurerm_lb_backend_address_pool" "eth1_1" {
  name            = "eth1_1"
  loadbalancer_id = azurerm_lb.PaloExt.id

  depends_on = [azurerm_linux_virtual_machine.vmseries]
}

### Create health probe on port 80 for Palo LB's ###
resource "azurerm_lb_probe" "PaloExt_http_probe" {
  name                = "http"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.PaloExt.id
  port                = 80
  protocol            = "http"
  request_path        = "/php/login.php"
  interval_in_seconds = 5
  number_of_probes    = 2

}

### Create TCP Load-Balancing rules for Palo Ext LB (see variables file for list of ports) ###
resource "azurerm_lb_rule" "tcp" {
  count                          = length(var.inbound_tcp_ports)
  name                           = "tcp-${element(var.inbound_tcp_ports, count.index)}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.PaloExt.id
  protocol                       = "TCP"
  frontend_port                  = element(var.inbound_tcp_ports, count.index)
  backend_port                   = element(var.inbound_tcp_ports, count.index)
  frontend_ip_configuration_name = "PaloLB_PubIP00"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.eth1_1.id
  probe_id                       = azurerm_lb_probe.PaloExt_http_probe.id
  enable_floating_ip             = true
  depends_on                     = [azurerm_lb.PaloExt, azurerm_lb_backend_address_pool.eth1_1]
  disable_outbound_snat          = true
}

### Create UDP Load-Balancing rules for Palo Ext LB (see variables file for list of ports) ###
resource "azurerm_lb_rule" "udp" {
  count                          = length(var.inbound_udp_ports)
  name                           = "udp-${element(var.inbound_udp_ports, count.index)}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.PaloExt.id
  protocol                       = "UDP"
  frontend_port                  = element(var.inbound_udp_ports, count.index)
  backend_port                   = element(var.inbound_udp_ports, count.index)
  frontend_ip_configuration_name = "PaloLB_PubIP00"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.eth1_1.id
  probe_id                       = azurerm_lb_probe.PaloExt_http_probe.id
  enable_floating_ip             = true
  depends_on                     = [azurerm_lb.PaloExt, azurerm_lb_backend_address_pool.eth1_1]
  disable_outbound_snat          = true

}

resource "azurerm_network_interface_backend_address_pool_association" "eth1_1" {
  for_each                = var.vmseries
  network_interface_id    = azurerm_network_interface.eth1_1[each.key].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eth1_1.id
}


resource "azurerm_lb" "PaloInt" {
  resource_group_name = var.resource_group_name
  location            = var.resource_location
  name                = "${var.loc_marker}-${var.coid}-LB-FW_TRUST"
  depends_on          = [azurerm_virtual_network.this]
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "PaloLB_PrivIP00"
    subnet_id = azurerm_subnet.this["LB"].id
  }
}

resource "azurerm_lb_probe" "PaloInt_http_probe" {
  name                = "http"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.PaloInt.id
  port                = 80
  protocol            = "http"
  request_path        = "/php/login.php"
  interval_in_seconds = 5
  number_of_probes    = 2

}

resource "azurerm_lb_backend_address_pool" "eth1_2" {
  name            = "eth1_2"
  loadbalancer_id = azurerm_lb.PaloInt.id

  depends_on = [azurerm_linux_virtual_machine.vmseries]
}

resource "azurerm_lb_rule" "allports" {
  name                           = "all-ports"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.PaloInt.id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "PaloLB_PrivIP00"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.eth1_2.id
  probe_id                       = azurerm_lb_probe.PaloInt_http_probe.id
  enable_floating_ip             = true
  depends_on                     = [azurerm_network_interface.eth1_2]
}

resource "azurerm_network_interface_backend_address_pool_association" "eth1_2" {
  for_each                = var.vmseries
  network_interface_id    = azurerm_network_interface.eth1_2[each.key].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.eth1_2.id
  depends_on              = [azurerm_network_interface.eth1_2]
}

output "PaloExt_lb_pip" {
  value = azurerm_public_ip.PaloExt.ip_address
}