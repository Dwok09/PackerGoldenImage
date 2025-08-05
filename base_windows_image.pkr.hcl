variable "s3_bucket_name" {
  type    = string
  default = "epic-test-bucket-894490"
}

variable "vmware_output_dir" {
  type    = string
  default = "output-vmware"
}

variable "vm_name" {
  type    = string
  default = "windows11-base"
}

packer {
  required_version = ">= 1.8.0"

  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# VMware builder (creates VMDK)
source "vmware-iso" "windows11" {
  iso_url           = "C:/Users/derek/Downloads/Win11_24H2_English_x64.iso"
  iso_checksum      = "B56B911BF18A2CEAEB3904D87E7C770BDF92D3099599D61AC2497B91BF190B11"
  guest_os_type     = "windows9-64"
  vm_name           = var.vm_name
  disk_size         = 61440
  disk_adapter_type = "nvme"
  cpus              = 2
  memory            = 4096
  floppy_files = [
    "./http/autounattend.xml",
    "./scripts/winrm.ps1",
    "./scripts/sysprep.ps1",
    "./bolt/windows_config"
  ]
  communicator      = "winrm"
  winrm_username    = "Administrator"
  winrm_password    = "Passw0rd"
  winrm_timeout     = "4h"
  shutdown_command  = "shutdown /s /t 45 /f"
  shutdown_timeout  = "1h"
  output_directory  = var.vmware_output_dir
  format            = "vmx"
  boot_wait         = "2s"
  boot_command      = ["<enter><wait1><enter><wait1><enter><wait1><enter>"]
  vmx_data = {
    firmware              = "efi"
    "floppy0.present"     = "FALSE"
  }
}

build {
  sources = ["source.vmware-iso.windows11"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for bolt to install. Rebooting in 2 min...'",
      "Start-Sleep -Seconds 120",
      "Restart-Computer -Force"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Copying files to temp dir...'",
      "New-Item -Path C:\\temp\\windows_config\\files -ItemType Directory -Force",
      "New-Item -Path C:\\temp\\windows_config\\plans -ItemType Directory -Force",
      
      "Copy-Item A:\\agent-config.yml C:\\temp\\windows_config\\files\\agent-config.yml -Force",
      "Copy-Item A:\\install.ps1 C:\\temp\\windows_config\\files\\install.ps1 -Force",
      "Copy-Item A:\\LaunchConfig.json C:\\temp\\windows_config\\files\\LaunchConfig.json -Force",

      "Copy-Item A:\\aws.pp C:\\temp\\windows_config\\plans\\aws.pp -Force",
      "Copy-Item A:\\base.pp C:\\temp\\windows_config\\plans\\base.pp -Force",
      "Copy-Item A:\\init.pp C:\\temp\\windows_config\\plans\\init.pp -Force",
      "Copy-Item A:\\puppet.pp C:\\temp\\windows_config\\plans\\puppet.pp -Force",
      "Copy-Item A:\\update.pp C:\\temp\\windows_config\\plans\\update.pp -Force",

      "Copy-Item A:\\bolt-project.yaml C:\\temp\\windows_config\\bolt-project.yaml -Force"
    ]
  }

  provisioner "powershell" {
    inline = [
      "bolt plan run windows_config --targets localhost --project C:\\temp\\windows_config"
    ]
  }

  provisioner "powershell" {
    inline = [
      "$sysprep = \"$Env:SystemRoot\\System32\\Sysprep\\Sysprep.exe\"",
      "Start-Process -Wait -FilePath $sysprep -ArgumentList '/generalize','/oobe','/shutdown','/quiet'"
    ]
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
    restart_timeout = "10m"
    restart_command = "shutdown /r /t 45 /f"
    timeout         = "10m"
  }

  post-processor "shell-local" {
    inline = [
      "C:\\'Program Files'\\VMware\\'VMware OVF Tool'\\ovftool.exe ${var.vmware_output_dir}/${var.vm_name}.vmx ${var.vmware_output_dir}/${var.vm_name}.ova"
    ]
  }

  post-processor "amazon-import" {
    region         = "us-east-1"
    s3_bucket_name = var.s3_bucket_name
    skip_clean     = false
    license_type   = "BYOL"

    tags = {
      Name    = "Windows11-Custom"
      Source  = "ISO"
      Version = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}