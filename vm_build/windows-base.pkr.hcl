packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "winsrv_iso_path" {
  type    = string
  default = "ISO/en-us_windows_server_2022_updated_july_2023_x64_dvd_541692c3.iso"
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

locals {
  vm_name_prefix = "wsc2024-mod-b"
  floppy_files_winsrv = [
      "scripts/win11/provision-autounattend.ps1",
      "scripts/win11/provision-openssh.ps1",
      "scripts/win11/provision-psremoting.ps1",
      "scripts/win11/provision-pwsh.ps1",
      "scripts/win11/provision-vmtools.ps1",
      "scripts/win11/provision-winrm.ps1",
      "scripts/winsrv/Autounattend.xml",
    ]
    floppy_files_core = [
      "scripts/win11/provision-autounattend.ps1",
      "scripts/win11/provision-openssh.ps1",
      "scripts/win11/provision-psremoting.ps1",
      "scripts/win11/provision-pwsh.ps1",
      "scripts/win11/provision-vmtools.ps1",
      "scripts/win11/provision-winrm.ps1",
      "scripts/winsrv-core/Autounattend.xml",
    ]
}

source "vsphere-iso" "winsrv-base" {
  CPUs          = 4
  RAM           = 6144
  guest_os_type = "windows2019srvNext_64Guest"
  disk_controller_type = ["pvscsi"]
  host                 = var.esx_host
  datastore            = var.esx_datastore
  insecure_connection  = true
  cdrom_type           = "sata"
  iso_paths            = [
    "[${var.esx_iso_datastore}] ${var.winsrv_iso_path}"
  ]
  password             = var.esx_password
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  network_adapters {
    network_card = "vmxnet3"
    network = var.esx_vm_network
  }
  export {
      output_format = "ova"
      output_directory = "./outputs"
  }
  username       = "root"
  vcenter_server = var.esx_host
  http_port_min  = 5100
  http_port_max  = 5150

  http_directory           = "http"
  shutdown_command         = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "Administrator"
  ssh_password             = "Skill39@Lyon"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

source "vsphere-iso" "win11-base" {
  CPUs          = 4
  RAM           = 6144
  guest_os_type = "windows9_64Guest"
  disk_controller_type = ["pvscsi"]
  host                 = var.esx_host
  datastore            = var.esx_datastore
  insecure_connection  = true
  password             = var.esx_password
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  network_adapters {
    network_card = "vmxnet3"
    network = var.esx_vm_network
  }
  export {
      output_format = "ova"
      output_directory = "./outputs"
  }
  username       = "root"
  vcenter_server = var.esx_host
  communicator             = "none"
}

build {
  # Build Windows server with GUI
  sources = ["vsphere-iso.winsrv-base"]
  source "vsphere-iso.winsrv-base" {
    name = "dc1"
    vm_name     = "${local.vm_name_prefix}-dc1"
    floppy_files = local.floppy_files_winsrv
  }

  # Build Windows server core
  source "vsphere-iso.winsrv-base" {
    name = "nw-srv"
    vm_name     = "${local.vm_name_prefix}-nw-srv"
    floppy_files = local.floppy_files_core
  }

  source "vsphere-iso.winsrv-base" {
    name = "file-srv"
    vm_name     = "${local.vm_name_prefix}-file-srv"
    floppy_files = local.floppy_files_winsrv
  }


  source "vsphere-iso.winsrv-base" {
    name = "web-srv"
    vm_name     = "${local.vm_name_prefix}-web-srv"
    floppy_files = local.floppy_files_winsrv
  }

  source "vsphere-iso.winsrv-base" {
    name = "paris-router"
    vm_name     = "${local.vm_name_prefix}-paris-router"
    floppy_files = local.floppy_files_winsrv

    network_adapters {
      network_card = "vmxnet3"
      network = "wsc"
    }

    network_adapters {
      network_card = "vmxnet3"
      network = "wsc"
    }

    network_adapters {
      network_card = "vmxnet3"
      network = "wsc"
    }
  }

  source "vsphere-iso.winsrv-base" {
    name = "la-router"
    vm_name     = "${local.vm_name_prefix}-la-router"
    floppy_files = local.floppy_files_winsrv

    network_adapters {
      network_card = "vmxnet3"
      network = "wsc"
    }
  }

  source "vsphere-iso.winsrv-base" {
    name = "lyon-router"
    vm_name     = "${local.vm_name_prefix}-lyon-router"
    floppy_files = local.floppy_files_winsrv

    network_adapters {
      network_card = "vmxnet3"
      network = "wsc"
    }

  }

  source "vsphere-iso.winsrv-base" {
    name = "dc2"
    vm_name     = "${local.vm_name_prefix}-dc2"
    floppy_files = local.floppy_files_winsrv
  }

  provisioner "powershell" {
    use_pwsh = true
    scripts   = [
      "scripts/win11/disable-windows-updates.ps1",
      "scripts/win11/disable-windows-defender.ps1"
    ]
  }

  provisioner "powershell" {
    use_pwsh = true
    inline = ["Rename-Computer -NewName ${replace(source.name, "${local.vm_name_prefix}-", "")}"]
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    scripts   = [
      "scripts/win11/enable-remote-desktop.ps1",
      "scripts/win11/optimize-powershell.ps1",
      "scripts/winsrv/provision-base.ps1"
    ]
  }
}

build {
  sources = ["vsphere-iso.win11-base"]
  source "vsphere-iso.win11-base" {
    name = "win-client1"
    vm_name     = "${local.vm_name_prefix}-win-client1"
  }

  source "vsphere-iso.win11-base" {
    name = "win-client2"
    vm_name     = "${local.vm_name_prefix}-win-client2"
  }
}