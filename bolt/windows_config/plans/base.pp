plan windows_config::base(
  String $local_temp_path,
  Boolean $ena_drivers,
  Boolean $nvme_drivers
) {

  run_task('powershell::script', $targets,
    script => "if (!(Test-Path -Path '${local_temp_path}')) { New-Item -ItemType Directory -Path '${local_temp_path}' }"
  )

  if $ena_drivers or $nvme_drivers {
    run_task('powershell::script', $targets,
      script => 'Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force'
    )
  }
}
