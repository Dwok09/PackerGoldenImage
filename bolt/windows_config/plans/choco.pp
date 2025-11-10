plan windows_config::choco(
  TargetSpec $targets,
) {
  apply_prep($targets)

  apply($targets) {
    # Read from modules/windows_config/files/installs.yaml
    $cfg   = parseyaml(file('windows_config/installs.yaml'))
    $src   = $cfg['source_name']
    $url   = $cfg['source_url']
    $pkgs  = $cfg['packages']
    $disable = $cfg['disable_community']

    class { 'chocolatey': }

    chocolateyfeature { 'allowGlobalConfirmation':
      ensure => enabled,
    }

    Package {
      provider => chocolatey,
      source   => $url,
    }

    $pkgs.each |String $name, Variant[String, Integer] $want| {
      package { $name:
        ensure => $want ? {
          'latest' => latest,
          'absent' => absent,
          default  => String($want),
        },
      }
    }
  }
}
