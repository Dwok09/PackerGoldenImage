plan windows_config::puppet(
  TargetSpec $targets,
  String $puppet_path,
  String $local_temp_path,
  String $remote_puppet_agent_url,
  String $puppet_server_dns,
  String $puppet_agent_start_mode,
  Array[String] $puppet_services,
  String $puppet_psk_path,
  String $puppet_psk_value,
  String $puppet_config_path
) {

  run_task('powershell::script', $targets,
    script => "if (!(Test-Path -Path '${puppet_path}')) { New-Item -ItemType Directory -Path '${puppet_path}' -Force }"
  )

  run_task('download_file', $targets,
    url => $remote_puppet_agent_url,
    destination => "${local_temp_path}\\PuppetAgent.msi"
  )

  try {
    run_task('reboot', $targets)
    wait_until_available($targets, wait_time => 1800)
  } catch {
    notice("Reboot failed, waiting for connection to stabilize")
    wait_until_available($targets, wait_time => 900)
  }

  # Install Puppet Agent
  run_task('package::windows', $targets,
    action => 'install',
    source => "${local_temp_path}\\PuppetAgent.msi",
    install_options => "PUPPET_MASTER_SERVER=${puppet_server_dns} /L*V C:\\windows\\temp\\puppet.log"
  )

  # Stop Puppet agent and set start mode
  $puppet_services.each |$service| {
    run_task('service', $targets,
      action => 'stop',
      name => $service,
      startup => $puppet_agent_start_mode
    )
  }

  # Add challenge password file
  $csr_content = @("CSR")
    extension_requests:
      pp_secret: ${puppet_psk_value}
    | CSR

  run_task('file::write', $targets,
    path => $puppet_psk_path,
    content => $csr_content
  )

  $puppet_conf_content = @("PUPPETCONF")
    [main]
    server = ${puppet_server_dns}
    [agent]
    use_srv_records = false
    | PUPPETCONF

  run_task('file::write', $targets,
    path => $puppet_config_path,
    content => $puppet_conf_content
  )
}
