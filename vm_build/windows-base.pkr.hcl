packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "winsrv_iso_url" {
  type    = string
  default = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
}

variable "winsrv_iso_checksum" {
  type    = string
  default = "sha256:e215493d331ebd57ea294b2dc96f9f0d025bc97b801add56ef46d8868d810053"
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

source "vsphere-iso" "winsrv-base" {
  CPUs          = 4
  RAM           = 4096
  guest_os_type = "windows2019srvNext_64Guest"
  disk_controller_type = ["pvscsi"]
  host                 = var.esx_host
  datastore            = var.esx_datastore
  insecure_connection  = true
  cdrom_type           = "sata"
  iso_paths            = [
    "[${var.esx_iso_datastore}] ISO/en-us_windows_server_2022_updated_july_2023_x64_dvd_541692c3.iso"
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
  username       = "root"
  vcenter_server = var.esx_host
  http_port_min  = 5100
  http_port_max  = 5150

  http_directory           = "http"
  shutdown_command         = "C:\System32\Sysprep\Sysprep.exe /oobe /generalize /shutdown"
  communicator             = "ssh"
  ssh_username             = "Administrator"
  ssh_password             = "AllTooWell13@"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

build {
  # Build Windows server with GUI
  source "vsphere-iso.winsrv-base" {
    vm_name     = "windows-2022-base"
    floppy_files = [
      "scripts/win11/provision-autounattend.ps1",
      "scripts/win11/provision-openssh.ps1",
      "scripts/win11/provision-psremoting.ps1",
      "scripts/win11/provision-pwsh.ps1",
      "scripts/win11/provision-vmtools.ps1",
      "scripts/win11/provision-winrm.ps1",
      "scripts/winsrv/Autounattend.xml",
    ]

  }

  # Build Windows server core
  source "vsphere-iso.winsrv-base" {
    name = "winsrv-core-base"
    vm_name     = "windows-2022-core-base"
    floppy_files = [
      "scripts/win11/provision-autounattend.ps1",
      "scripts/win11/provision-openssh.ps1",
      "scripts/win11/provision-psremoting.ps1",
      "scripts/win11/provision-pwsh.ps1",
      "scripts/win11/provision-vmtools.ps1",
      "scripts/win11/provision-winrm.ps1",
      "scripts/winsrv-core/Autounattend.xml",
    ]
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/disable-windows-defender.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/enable-remote-desktop.ps1"
  }

  provisioner "powershell" {
    script   = "scripts/win11/optimize-powershell.ps1"
  }

  provisioner "powershell" {
    inline = [
      "(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi', 'C:\\Users\\Administrator\\Desktop\\requestRouter_amd64.msi')",
      "(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi', 'C:\\Users\\Administrator\\Desktop\\rewrite_amd64_en-US.msi')",
    ]
  }

}