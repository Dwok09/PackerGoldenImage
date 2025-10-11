
plan windows_config::aws(
  TargetSpec $targets,
  String $local_temp_path,
  Boolean $ena_drivers,
  Boolean $nvme_drivers,
  Boolean $ssm_agent,
  Boolean $ec2launch_v1,
  Boolean $ec2launch_v2,
  String $remote_aws_cli_url,
  String $remote_aws_ena_drivers_url,
  String $remote_aws_nvme_drivers_url,
  String $remote_aws_ssm_agent_url,
  String $remote_aws_ec2_launch_v1_url,
  String $remote_aws_ec2_launch_v2_url,
  String $ec2launch_v1_launch_config_path,
  String $ec2launch_v2_agent_config_path
) {

  # Download AWS CLI
  run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_cli_url}' -OutFile '${local_temp_path}\\AWSCLIV2.msi'\"", $targets)

  if $ena_drivers and $remote_aws_ena_drivers_url {
    run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_ena_drivers_url}' -OutFile '${local_temp_path}\\AwsEnaNetworkDriver.zip'\"", $targets)
  }

  if $nvme_drivers and $remote_aws_nvme_drivers_url {
    run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_nvme_drivers_url}' -OutFile '${local_temp_path}\\AWSNVMe.zip'\"", $targets)
  }

  if $ssm_agent and $remote_aws_ssm_agent_url {
    run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_ssm_agent_url}' -OutFile '${local_temp_path}\\AmazonSSMAgentSetup.exe'\"", $targets)
  }

  if $ec2launch_v1 and $remote_aws_ec2_launch_v1_url {
    run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_ec2_launch_v1_url}' -OutFile '${local_temp_path}\\EC2Launch.zip'\"", $targets)
  }

  if $ec2launch_v2 and $remote_aws_ec2_launch_v2_url {
    run_command("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${remote_aws_ec2_launch_v2_url}' -OutFile '${local_temp_path}\\AmazonEC2Launch.msi'\"", $targets)
  }

  if $ena_drivers {
    run_command("powershell.exe -NoProfile -Command \"Expand-Archive -Path '${local_temp_path}\\AwsEnaNetworkDriver.zip' -DestinationPath '${local_temp_path}\\AWSEnaNetworkDriver' -Force\"", $targets)
    run_command("powershell.exe -NoProfile -Command \"& '${local_temp_path}\\AWSEnaNetworkDriver\\install.ps1'\"", $targets)
  }

  if $nvme_drivers {
    run_command("powershell.exe -NoProfile -Command \"Expand-Archive -Path '${local_temp_path}\\AWSNVMe.zip' -DestinationPath '${local_temp_path}\\AWSNVMe' -Force\"", $targets)
    run_command("powershell.exe -NoProfile -Command \"& '${local_temp_path}\\AWSNVMe\\install.ps1'\"", $targets)
  }

  # Install AWS CLI
  run_command("msiexec.exe /i \"${local_temp_path}\\AWSCLIV2.msi\" /qn /norestart", $targets)

  if $ssm_agent {
    run_command("msiexec.exe /i \"${local_temp_path}\\AmazonSSMAgentSetup.exe\" /qn /norestart", $targets)
  }

  if $ec2launch_v1 {
    upload_file("windows_config/install.ps1", "${local_temp_path}\\install.ps1", $targets)
    run_command("powershell.exe -NoProfile -Command \"& '${local_temp_path}\\install.ps1'\"", $targets)
  }

  if $ec2launch_v2 {
    run_command("msiexec.exe /i \"${local_temp_path}\\AmazonEC2Launch.msi\" /qn /norestart", $targets)
  }

  if $ec2launch_v1 and $ec2launch_v1_launch_config_path {
    upload_file("windows_config/LaunchConfig.json", $ec2launch_v1_launch_config_path, $targets)
  }

  if $ec2launch_v2 and $ec2launch_v2_agent_config_path {
    upload_file("windows_config/agent-config.yml", $ec2launch_v2_agent_config_path, $targets)
  }
}
