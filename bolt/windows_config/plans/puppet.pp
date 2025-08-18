plan windows_config::puppet(
  TargetSpec $targets
) {
  # Create directory structure
  run_command("New-Item -ItemType Directory -Force -Path 'C:/Temp/PuppetTest'", $targets)

  # Download Puppet agent
  run_command(
    "powershell.exe -Command \"Invoke-WebRequest -Uri 'https://downloads.puppet.com/windows/puppet-agent-x64-latest.msi' -OutFile 'C:/Temp/PuppetTest/PuppetAgent.msi' -UseBasicParsing\"",
    $targets
  )

  # Install Puppet
  run_command(
    "msiexec /i C:/Temp/PuppetTest/PuppetAgent.msi /qn /norestart PUPPET_MASTER_SERVER=puppet.it.epicgames.com",
    $targets
  )

  # Configure services
  run_command(
    "powershell.exe -Command \"Get-Service *puppet* | Stop-Service puppet -ErrorAction SilentlyContinue\"",
    $targets
  )

  run_command(
    "powershell.exe -Command \"Get-Service *puppet* | Set-Service puppet -StartupType Manual \"",
    $targets
  )

  run_command(
    "powershell.exe -Command \"@('custom_attributes:', '  challengePassword: TEST-SECRET') | Out-File 'C:/ProgramData/PuppetLabs/puppet/etc/csr_attributes.yaml' -Encoding ASCII\"",
    $targets
  )

  upload_file(
    'windows_config/files/puppet.conf',  # Source path relative to module
    'C:/ProgramData/PuppetLabs/puppet/etc/puppet.conf',  # Destination path
    $targets
  )
}
