plan windows_config::aws(
) {
  run_task('download_file', $targets,
    url => $remote_aws_cli_url,
    destination => "${local_temp_path}\\AWSCLIV2.msi"
  )

  if $ena_drivers and $remote_aws_ena_drivers_url {
    run_task('download_file', $targets,
      url => $remote_aws_ena_drivers_url,
      destination => "${local_temp_path}\\AwsEnaNetworkDriver.zip"
    )
  }

  if $nvme_drivers and $remote_aws_nvme_drivers_url {
    run_task('download_file', $targets,
      url => $remote_aws_nvme_drivers_url,
      destination => "${local_temp_path}\\AWSNVMe.zip"
    )
  }

  if $ssm_agent and $remote_aws_ssm_agent_url {
    run_task('download_file', $targets,
      url => $remote_aws_ssm_agent_url,
      destination => "${local_temp_path}\\AmazonSSMAgentSetup.exe"
    )
  }

  if $ec2launch_v1 and $remote_aws_ec2_launch_v1_url {
    run_task('download_file', $targets,
      url => $remote_aws_ec2_launch_v1_url,
      destination => "${local_temp_path}\\EC2Launch.zip"
    )
  }

  if $ec2launch_v2 and $remote_aws_ec2_launch_v2_url {
    run_task('download_file', $targets,
      url => $remote_aws_ec2_launch_v2_url,
      destination => "${local_temp_path}\\AmazonEC2Launch.msi"
    )
  }

  if $ena_drivers {
    run_task('powershell::script', $targets,
      script => "Expand-Archive -Path '${local_temp_path}\\AwsEnaNetworkDriver.zip' -DestinationPath '${local_temp_path}\\AWSEnaNetworkDriver' -Force"
    )
  }

  if $nvme_drivers {
    run_task('powershell::script', $targets,
      script => "Expand-Archive -Path '${local_temp_path}\\AWSNVMe.zip' -DestinationPath '${local_temp_path}\\AWSNVMe' -Force"
    )
  }

  run_task('package::windows', $targets,
    action => 'install',
    source => "${local_temp_path}\\AWSCLIV2.msi"
  )

  if $ena_drivers {
    run_task('powershell::script', $targets,
      script => "& '${local_temp_path}\\AWSEnaNetworkDriver\\install.ps1'"
    )
  }

  if $nvme_drivers {
    run_task('powershell::script', $targets,
      script => "& '${local_temp_path}\\AWSNVMe\\install.ps1'"
    )
  }

  if $ssm_agent {
    run_task('package::windows', $targets,
      action => 'install',
      source => "${local_temp_path}\\AmazonSSMAgentSetup.exe",
      install_options => '/quiet'
    )
  }

  if $ec2launch_v1 {
    upload_file("windows_config/install.ps1", "${local_temp_path}\\install.ps1", $targets)
  }

  if $ec2launch_v1 {
    run_task('powershell::script', $targets,
      script => "& '${local_temp_path}\\install.ps1'"
    )
  }

  if $ec2launch_v2 {
    run_task('package::windows', $targets,
      action => 'install',
      source => "${local_temp_path}\\AmazonEC2Launch.msi"
    )
  }

  if $ec2launch_v1 and $ec2launch_v1_launch_config_path {
    upload_file("windows_config/LaunchConfig.json", $ec2launch_v1_launch_config_path, $targets)
  }

  if $ec2launch_v2 and $ec2launch_v2_agent_config_path {
    upload_file("windows_config/agent-config.yml", $ec2launch_v2_agent_config_path, $targets)
  }
}
