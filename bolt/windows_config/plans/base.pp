plan windows_config::base(
  TargetSpec $targets,
  String $local_temp_path,
  Boolean $ena_drivers,
  Boolean $nvme_drivers
) {

  run_command("if (!(Test-Path -Path '${local_temp_path}')) { New-Item -ItemType Directory -Path '${local_temp_path}'}", $targets)

  if $ena_drivers or $nvme_drivers {
    run_command('Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force', $targets)
  }
}
