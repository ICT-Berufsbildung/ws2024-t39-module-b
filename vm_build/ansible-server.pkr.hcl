packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "esx_host" {
  type    = string
  default = "esx1.homenet.local"
}

variable "esx_username" {
  type    = string
  default = "root"
}

variable "esx_password" {
  type    = string
}

variable "esx_datastore" {
  type    = string
  default = "datastor3_512GB"
}

variable "esx_iso_datastore" {
  type    = string
  default = "datastore2_1TB"
}

variable "esx_vm_network" {
  type    = string
  default = "VM Network"
}

variable "marking_secret" {
  type    = string
}

source "vsphere-iso" "base" {
  CPUs         = 4
  RAM          = 6144
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg interface=ens192<wait>", "<enter><wait>"
  ]
  disk_controller_type = ["pvscsi"]
  guest_os_type        = "debian11Guest"
  host                 = var.esx_host
  datastore            = var.esx_datastore
  insecure_connection  = true
  cdrom_type           = "sata"
  iso_paths            = [
    "[${var.esx_iso_datastore}] ISO/debian-12.5.0-amd64-netinst.iso"
  ]
  password             = var.esx_password
  ssh_password         = "Skill39@Lyon"
  ssh_username         = "appadmin"
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  username       = "root"
  vcenter_server = var.esx_host
  http_directory = "http"
  http_port_min  = 5100
  http_port_max  = 5150

  export {
      output_format = "ova"
      output_directory = "./outputs"
  }

}

# ANSIBLE-SRV
build {
  name = "ANSIBLE-SRV"
  sources = ["source.vsphere-iso.base"]
  source "source.vsphere-iso.base" {
    vm_name = "wsc2024-mod-b-ansible-srv"
    network_adapters {
      network_card = "vmxnet3"
      network = var.esx_vm_network
    }
  }

  provisioner "shell-local" {
    inline = ["echo -n ${var.marking_secret} | openssl aes-256-cbc -a -pbkdf2 -in ./http/marking_shares.yml -out ./http/ansible_marking.enc -pass stdin"]
  }

  provisioner "file" {
    generated = true
    source = "./http/ansible_marking.enc"
    destination = "/tmp/marking.enc"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; echo 'Skill39@Lyon' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script = "./scripts/prepare-ansible-srv.sh"
  }

  provisioner "file" {
    source = "../ansible_automation/inventory"
    destination = "/opt/ansible/"
  }

  provisioner "file" {
    source = "../ansible_automation/ansible.cfg"
    destination = "/opt/ansible/"
  }

}