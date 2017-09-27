##############################################################################
# Create Linux Servers with the SSH keys
##############################################################################
resource "ibm_compute_vm_instance" "linux_node" {
  count                = 1
  hostname             = "lintest-${count.index+1}"
  domain               = "test.local"
  ssh_key_ids          = ["${ibm_compute_ssh_key.public_key.id}"]
  os_reference_code    = "CENTOS_6_64"
  datacenter           = "${var.datacenter}"
  network_speed        = 1000
  private_vlan_id      = "${var.vlan_engine1}"
  cores                = 1
  memory               = 4096
  hourly_billing       = true
  private_network_only = true
  local_disk           = true
  hourly_billing       = true
  #file_storage_ids     = ["${ibm_storage_file.fs_endurance.id}"]

  provisioner "remote-exec" {
      inline = [
      "yum -y install httpd",
      "apachectl start",
      "apachectl start",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      private_key = "${file("${var.private_key}")}"
  }
  }

  #Create the bootsrap package by zipping the content of bootsrap directory
  provisioner "local-exec" {
      command = "rm bootstrap.zip;zip ./bootstrap.zip ./bootstrap/*"
  }

  # Copies the bootstrap file to the home directory of the http server
  provisioner "file" {
    source      = "bootstrap.zip"
    destination = "/var/www/html/bootstrap.zip"

    connection {
      type     = "ssh"
      user     = "root"
      private_key = "${file("${var.private_key}")}"
  }
  }

}

##############################################################################
# DNS Registrations
##############################################################################
resource "ibm_dns_record" "lin" {
    count       = 1
    data        = "${element(ibm_compute_vm_instance.linux_node.*.ipv4_address_private, count.index)}"
    domain_id   = "${ibm_dns_domain.dns-domain-test.id}"
    host        = "${element(ibm_compute_vm_instance.linux_node.*.hostname, count.index)}"
    #responsible_person = "user@softlayer.com"
    ttl = 900
    type = "a"
}

##############################################################################
# Outputs
##############################################################################


output "linux_node_id" {
  value = ["${ibm_compute_vm_instance.linux_node.*.id}"]
  }

output "linux_node_ip_addresses" {
  value = ["${ibm_compute_vm_instance.linux_node.*.ipv4_address_private}"]
  }


