source "amazon-ebs" "win" {
  region                  = "us-east-1"
  instance_type           = "t3.small"
  ami_name                = "windows-base-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  ami_description         = "Base Windows image built by Packer"
  communicator            = "winrm"
  winrm_username          = "Administrator"
  winrm_password          = "Passw0rd"
  winrm_insecure          = true
  winrm_use_ssl           = true
  winrm_timeout           = "2h"
  user_data               = templatefile("${path.root}/user_data_winrm.ps1.tmpl", {})

  tags = {
    Name = "derek-test-ami"
    BuiltBy = "packer"
    Service = "megastation"
    Owner = "Derek Walker"
    Contact = "derek.walker@xa.epicgames.com"
    EUID = "Testing for megastation provisioning"
  }

  run_tags = {
    Name = "derek-test-ami"
    BuiltBy = "packer"
    Service = "megastation"
    Owner = "Derek Walker"
    Contact = "derek.walker@xa.epicgames.com"
    EUID = "Testing for megastation provisioning"
  }

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["801119661308"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 60
    volume_type = "gp3"
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.win"]

  provisioner "file" {
    source      = "./bolt"
    destination = "C:/temp"
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing chocolatey...'",
      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing puppet bolt...'",
      "choco install puppet-bolt -y",
      "Write-Host 'Waiting for bolt to install. Rebooting in 2 min...'",
      "Start-Sleep -Seconds 120",
      "Restart-Computer -Force"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing puppet bolt module...'",
      "bolt module install --project C:\\temp\\bolt\\windows_config --no-color",
      "Import-Module PuppetBolt"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Running puppet bolt module...'",
      "bolt plan run windows_config --project C:\\temp\\bolt\\windows_config --targets localhost"
    ]
  }


  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep...'",
      "$sysprep = \"$Env:SystemRoot\\System32\\Sysprep\\Sysprep.exe\"",
      "Start-Process -Wait -FilePath $sysprep -ArgumentList '/generalize','/oobe','/shutdown','/quiet', '/unattned:C:\\temp\\sysprep-unattend.xml'"
    ]
  }
}