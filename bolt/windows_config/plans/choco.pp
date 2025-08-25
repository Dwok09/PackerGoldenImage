plan windows_config::choco(
  TargetSpec $targets,
  String $source_name,
  String $source_url,
  Hash[String, Variant[String, Integer]] $packages = {},
) {

  $packages_json = to_json($packages)

  $args = [
    "-SourceName",     $source_name,
    "-SourceUrl",      $source_url,
  ]

  $args += ["-PackagesJson", $packages_json]

  $result = run_script('windows_config/choco_helper.ps1', $targets, $args)

  notice("Chocolatey install + source + package operations completed on ${targets}.")
  return $result
}
