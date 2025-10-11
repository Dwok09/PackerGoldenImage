plan windows_config::puppet(
  TargetSpec $targets = 'localhost',
) {

  run_command("powershell.exe -NoProfile -Command New-Item -ItemType Directory -Force -Path 'C:\\Temp\\PuppetTest' | Out-Null", $targets)

  run_command(
    "powershell.exe -NoProfile -Command \"Invoke-WebRequest -Uri 'https://downloads.puppet.com/windows/puppet-agent-x64-latest.msi' -OutFile 'C:\\Temp\\PuppetTest\\PuppetAgent.msi' -UseBasicParsing\"",
    $targets
  )

  run_command(
    "msiexec /i \"C:\\Temp\\PuppetTest\\PuppetAgent.msi\" /qn /norestart PUPPET_MASTER_SERVER=puppet.it.epicgames.com",
    $targets
  )

  run_command(
    "powershell.exe -NoProfile -Command \"Get-Service -Name '*puppet*' | ForEach-Object { try { Stop-Service -Name \$_.Name -Force -ErrorAction SilentlyContinue } catch {} ; try { Set-Service -Name \$_.Name -StartupType Manual -ErrorAction SilentlyContinue } catch {} }\"",
    $targets
  )

  run_command(
    "powershell.exe -NoProfile -Command \"New-Item -ItemType Directory -Force -Path 'C:\\ProgramData\\PuppetLabs\\puppet\\etc' | Out-Null\"",
    $targets
  )

  run_command(
    "powershell.exe -NoProfile -Command \"@('custom_attributes:', '  challengePassword: TEST-SECRET') | Set-Content -Path 'C:\\ProgramData\\PuppetLabs\\puppet\\etc\\csr_attributes.yaml' -Encoding ASCII -Force\"",
    $targets
  )

  upload_file(
    'windows_config/puppet.conf',
    'C:/ProgramData/PuppetLabs/puppet/etc/puppet.conf',
    $targets
  )

  notice('Puppet agent installed, services configured, csr_attributes.yaml written, and puppet.conf uploaded.')
}
