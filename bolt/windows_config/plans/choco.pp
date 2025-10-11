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
    $disable = $cfg['disable_community'] # assumed present if you use it

    class { 'chocolatey': }

    chocolateyfeature { 'allowGlobalConfirmation':
      ensure => enabled,
    }

    # Configure your internal source (no creds)
    chocolateysource { $src:
      ensure   => present,
      location => $url,
      priority => 1,
    }

    # Default all packages to Chocolatey + your source
    Package {
      provider => chocolatey,
      source   => $src,
    }

    # Install packages from YAML (version string, 'latest', or 'absent')
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
