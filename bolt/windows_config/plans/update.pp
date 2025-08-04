plan windows_config::update(
  Array[String] $win_updates_categories,
  String $win_updates_log_path
) {
  $update_script = @("UPDATE"/)
    \$session = New-Object -ComObject Microsoft.Update.Session
    \$searcher = \$session.CreateUpdateSearcher()
    \$result = \$searcher.Search("IsInstalled=0 and Type='Software'")
    \$updates = \$result.Updates
    \$updates | Select-Object Title, Description, KBArticleIDs | ConvertTo-Json | Out-File '${win_updates_log_path}'
    \$rebootRequired = \$false
    foreach (\$update in \$updates) {
      if (\$update.InstallationBehavior.RebootBehavior -ne 0) {
        \$rebootRequired = \$true
        break
      }
    }
    @{updates = \$updates.Count; reboot_required = \$rebootRequired} | ConvertTo-Json
    | UPDATE

  $update_result = run_task('powershell::script', $targets,
    script => $update_script
  ).first.value['_output'].parsejson()

  if $update_result['reboot_required'] {
    run_task('reboot', $targets)
    wait_until_available($targets, wait_time => 1800)
  }

  $install_script = @("INSTALL"/)
    \$session = New-Object -ComObject Microsoft.Update.Session
    \$updater = \$session.CreateUpdateInstaller()
    \$searcher = \$session.CreateUpdateSearcher()
    \$result = \$searcher.Search("IsInstalled=0 and Type='Software'")
    \$updater.Updates = \$result.Updates
    \$installationResult = \$updater.Install()
    \$installationResult | ConvertTo-Json | Out-File '${win_updates_log_path}' -Append
    @{result = \$installationResult.ResultCode; reboot_required = \$installationResult.RebootRequired} | ConvertTo-Json
    | INSTALL

  run_task('powershell::script', $targets,
    script => $install_script
  )
}
