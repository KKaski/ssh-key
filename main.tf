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
variable vlan_engine1 {
  description = "Private vlan for engine1 group"
}
variable vlan_engine2 {
  description = "Private vlan for engine2 group"
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
# Create Shared File Storage 
##############################################################################
resource "ibm_storage_file" "fs_endurance" {
        type = "Endurance"
        datacenter = "${var.datacenter}"
        capacity = 20
        iops = 0.25

        snapshot_capacity = 10
        #hourly_billing       = true
}

##############################################################################
# Create Shared Block Storage 
##############################################################################
resource "ibm_storage_block" "fs_block" {
        type = "Performance"
        datacenter = "${var.datacenter}"
        capacity = 20
        iops = 100
        os_format_type = "Windows 2008+"

        snapshot_capacity = 10  
        #hourly_billing       = true
}

##############################################################################
# Create Windows Servers with the SSH keys
##############################################################################
resource "ibm_compute_vm_instance" "win_node" {
  count                = "${var.node_count}"
  hostname             = "wintest-${count.index+1}"
  domain               = "test.local"
  ssh_key_ids          = ["${ibm_compute_ssh_key.public_key.id}"]
  os_reference_code    = "WIN_2012-STD-R2_64"
  datacenter           = "${var.datacenter}"
  network_speed        = 10
  private_vlan_id      = "${var.vlan_engine1}"
  cores                = 1
  memory               = 1024
  hourly_billing       = true
  private_network_only = true
  local_disk           = true
  hourly_billing       = true
  file_storage_ids    = ["${ibm_storage_file.fs_endurance.id}"]
  #block_storage_ids    = ["${ibm_storage_block.fs_block.id}"]
  user_metadata = <<EOF
  #ps1_sysnative
  script: |
  <powershell>
    New-NetIPAddress -IPAddress 10.62.129.${count.index+1} -InterfaceAlias 'Ethernet 2'
    mount '${ibm_storage_file.fs_endurance.mountpoint}' Y:
  </powershell>
  EOF
}

##############################################################################
# IBM DNS Domain: For registering the VMs
##############################################################################
resource "ibm_dns_domain" "dns-domain-test" {
    name = "test.local.com"
    #target = "127.0.0.10"
}

##############################################################################
# DNS Registrations
##############################################################################
resource "ibm_dns_record" "win" {
    count       = "${var.node_count}"
    data        = "${element(ibm_compute_vm_instance.win_node.*.ipv4_address_private, count.index)}"
    domain_id   = "${ibm_dns_domain.dns-domain-test.id}"
    host        = "${element(ibm_compute_vm_instance.win_node.*.hostname, count.index)}"
    #responsible_person = "user@softlayer.com"
    ttl = 900
    type = "a"
}

##############################################################################
# Outputs
##############################################################################
output "ssh_key_id" {
  value = "${ibm_compute_ssh_key.public_key.id}"
}

output "win_node_id" {
  value = ["${ibm_compute_vm_instance.win_node.*.id}"]
  }

output "win_node_ip_addresses" {
  value = ["${ibm_compute_vm_instance.win_node.*.ipv4_address_private}"]
  }

output "mountpoint" {
  value = ["${ibm_storage_file.fs_endurance.mountpoint}"]
}
