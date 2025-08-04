plan windows_config(
  TargetSpec $targets,
  String $local_temp_path = 'C:\\temp',
  
  Boolean $win_updates = true,
  Array[String] $win_updates_categories = ['SecurityUpdates', 'CriticalUpdates', 'UpdateRollups', 'Updates'],
  String $win_updates_log_path = 'C:\\windows\\temp\\ansible_win_update.log',
  
  Optional[String] $cloudsmith_token = undef,
  String $package_base_url = "https://dl.cloudsmith.io/${cloudsmith_token}/epic-it/build_services/raw/versions/latest",
  
  Boolean $ena_drivers = false,
  Boolean $nvme_drivers = false,
  Boolean $ssm_agent = false,
  Boolean $ec2launch_v1 = false,
  Boolean $ec2launch_v2 = true,
  String $ec2launch_v1_launch_config_path = 'C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Config\\LaunchConfig.json',
  String $ec2launch_v2_agent_config_path = 'C:\\ProgramData\\Amazon\\EC2Launch\\config\\agent-config.yml',
  
  String $puppet_server_dns = 'puppet.it.epicgames.com',
  String $puppet_path = 'C:\\ProgramData\\PuppetLabs\\puppet\\etc',
  Array[String] $puppet_services = ['pxp-agent'],
  String $puppet_psk_path = 'C:\\ProgramData\\PuppetLabs\\puppet\\etc\\csr_attributes.yaml',
  String $puppet_psk_value = '',
  String $puppet_agent_start_mode = 'disabled',
  String $puppet_config_path = 'C:\\ProgramData\\PuppetLabs\\puppet\\etc\\puppet.conf'
) {

  $remote_puppet_agent_url = "${package_base_url}/PuppetAgent.msi"
  $remote_aws_cli_url = "${package_base_url}/AWSCLIV2.msi"
  $remote_aws_ena_drivers_url = "${package_base_url}/AwsEnaNetworkDriver.zip"
  $remote_aws_nvme_drivers_url = "${package_base_url}/AWSNVMe.zip"
  $remote_aws_ssm_agent_url = "${package_base_url}/AmazonSSMAgentSetup.exe"
  $remote_aws_ec2_launch_v1_url = "${package_base_url}/EC2-Windows-Launch.zip"
  $remote_aws_ec2_launch_v2_url = "${package_base_url}/AmazonEC2Launch.msi"

  run_plan('windows_config::base', 
    targets => $targets,
    local_temp_path => $local_temp_path,
    ena_drivers => $ena_drivers,
    nvme_drivers => $nvme_drivers
  )

  if $win_updates {
    run_plan('windows_config::update',
      targets => $targets,
      win_updates_categories => $win_updates_categories,
      win_updates_log_path => $win_updates_log_path
    )
  }

  run_plan('windows_config::puppet',
    targets => $targets,
    puppet_path => $puppet_path,
    local_temp_path => $local_temp_path,
    remote_puppet_agent_url => $remote_puppet_agent_url,
    puppet_server_dns => $puppet_server_dns,
    puppet_agent_start_mode => $puppet_agent_start_mode,
    puppet_services => $puppet_services,
    puppet_psk_path => $puppet_psk_path,
    puppet_psk_value => $puppet_psk_value,
    puppet_config_path => $puppet_config_path
  )

  run_plan('windows_config::aws',
    targets => $targets,
    local_temp_path => $local_temp_path,
    ena_drivers => $ena_drivers,
    nvme_drivers => $nvme_drivers,
    ssm_agent => $ssm_agent,
    ec2launch_v1 => $ec2launch_v1,
    ec2launch_v2 => $ec2launch_v2,
    remote_aws_cli_url => $remote_aws_cli_url,
    remote_aws_ena_drivers_url => $remote_aws_ena_drivers_url,
    remote_aws_nvme_drivers_url => $remote_aws_nvme_drivers_url,
    remote_aws_ssm_agent_url => $remote_aws_ssm_agent_url,
    remote_aws_ec2_launch_v1_url => $remote_aws_ec2_launch_v1_url,
    remote_aws_ec2_launch_v2_url => $remote_aws_ec2_launch_v2_url,
    ec2launch_v1_unattend_xml_path => $ec2launch_v1_unattend_xml_path,
    ec2launch_v2_unattend_xml_path => $ec2launch_v2_unattend_xml_path,
    ec2launch_v1_launch_config_path => $ec2launch_v1_launch_config_path,
    ec2launch_v2_agent_config_path => $ec2launch_v2_agent_config_path
  )
}
