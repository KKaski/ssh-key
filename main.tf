##############################################################################
# Require terraform 0.9.3 or greater
##############################################################################
terraform {
  required_version = ">= 0.9.3"
}
##############################################################################
# IBM Cloud Provider
##############################################################################
# See the README for details on ways to supply these values
provider "ibm" {
  bluemix_api_key = "${var.bxapikey}"
  softlayer_username = "${var.slusername}"
  softlayer_api_key = "${var.slapikey}"
}

##############################################################################
# Variables
##############################################################################
variable bxapikey {
  description = "Your Bluemix API Key."
}
variable slusername {
  description = "Your Softlayer username."
}
variable slapikey {
  description = "Your Softlayer API Key."
}
variable datacenter {
  description = "The datacenter to create resources in."
}
variable public_key {
  description = "Your public SSH key material."
}
variable key_label {
  description = "A label for the SSH key that gets created."
}
variable key_note {
  description = "A note for the SSH key that gets created."
}
variable node_count {
  default=1
  description = "Number of nodes to create"
}

##############################################################################
# IBM SSH Key: For connecting to VMs
##############################################################################
resource "ibm_compute_ssh_key" "public_key" {
  label = "${var.key_label}"
  notes = "${var.key_note}"
  # Public key, so this is completely safe
  public_key = "${var.public_key}"
}

##############################################################################
# Create Servers with the SSH keys
##############################################################################
resource "ibm_compute_vm_instance" "my_server_1" {
  count                = "${var.node_count}"
  hostname             = "kktest-${count.index+1}"
  domain               = "test.local"
  ssh_key_ids          = ["${ibm_compute_ssh_key.public_key.id}"]
  os_reference_code    = "CENTOS_6_64"
  datacenter           = "${var.datacenter}"
  network_speed        = 10
  cores                = 1
  memory               = 1024
  hourly_billing       = true
  private_network_only = true
  local_disk           = true
  hourly_billing       = true
}

##############################################################################
# Outputs
##############################################################################
output "ssh_key_id" {
  value = "${ibm_compute_ssh_key.public_key.id}"
}

output "node_ids" {
  value = ["${ibm_compute_vm_instance.node.*.id}"]
  }

output "node_ip_addresses" {
  value = ["${ibm_compute_vm_instance.node.*.ipv4_address}"]
  }
