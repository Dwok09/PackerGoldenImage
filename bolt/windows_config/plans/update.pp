plan windows_config::update(
  Array[String] $win_updates_categories,
  String $win_updates_log_path,
  TargetSpec $targets
) {
  $update_script = @("UPDATE")
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
    @{updates = \$updates.Count; reboot_required = \$rebootRequired} | ConvertTo-Json -Compress
"UPDATE"

  $update_result = run_command($update_script, $targets).first.value['_output']
  # Add error handling for JSON parsing
  $parsed_result = try {
    $update_result.parsejson()
  } catch {
    fail("Failed to parse update results: ${_}")
  }

  if $parsed_result['reboot_required'] {
    run_task('reboot', $targets)
    wait_until_available($targets, wait_time => 1800)
  }

  $install_script = @("INSTALL")
    \$session = New-Object -ComObject Microsoft.Update.Session
    \$updater = \$session.CreateUpdateInstaller()
    \$searcher = \$session.CreateUpdateSearcher()
    \$result = \$searcher.Search("IsInstalled=0 and Type='Software'")
    \$updater.Updates = \$result.Updates
    \$installationResult = \$updater.Install()
    \$installationResult | ConvertTo-Json | Out-File '${win_updates_log_path}' -Append
    @{result = \$installationResult.ResultCode; reboot_required = \$installationResult.RebootRequired} | ConvertTo-Json -Compress
"INSTALL"

  run_command($install_script, $targets)
}
