plan windows_config(
  TargetSpec $targets,
  String $local_temp_path = 'C:\\temp',
  
  Boolean $win_updates = true,
  Array[String] $win_updates_categories = ['SecurityUpdates', 'CriticalUpdates', 'UpdateRollups', 'Updates'],
  String $win_updates_log_path = 'C:\\windows\\temp\\ansible_win_update.log',

  Optional[String] $cloudsmith_token = "em69KjexQOI0d8rA",
  String $package_base_url = "https://dl.cloudsmith.io/${cloudsmith_token}/epic-it/build_services/raw/versions/latest",

  Boolean $ena_drivers = false,
  Boolean $nvme_drivers = false,
  Boolean $ssm_agent = false,
  Boolean $ec2launch_v1 = false,
  Boolean $ec2launch_v2 = true,
  String $ec2launch_v1_launch_config_path = 'C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Config\\LaunchConfig.json',
  String $ec2launch_v2_agent_config_path = 'C:\\ProgramData\\Amazon\\EC2Launch\\config\\agent-config.yml',
) {

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

  run_plan('windows_config::puppet',
    targets => $targets,
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
    ec2launch_v1_launch_config_path => $ec2launch_v1_launch_config_path,
    ec2launch_v2_agent_config_path => $ec2launch_v2_agent_config_path
  )
}
