param(
  [Parameter(Mandatory=$true)][string]$SourceName,
  [Parameter(Mandatory=$true)][string]$SourceUrl,
  [string]$SourceUser,
  [string]$SourcePassword,
  [Parameter(Mandatory=$true)][string]$PackagesJson
)

$ErrorActionPreference = 'Stop'

function Ensure-Tls12 {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

function Ensure-Chocolatey {
  if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Ensure-Tls12
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $script = 'https://community.chocolatey.org/install.ps1'
    Invoke-Expression ((New-Object Net.WebClient).DownloadString($script))
  } else {
    Write-Host "Chocolatey already installed."
  }
}

function Ensure-ChocoSource {
  param([string]$Name, [string]$Url, [string]$User, [string]$Pass)

  # Remove if exists (so URL/creds/priority stay in sync)
  $existing = choco source list --allow-unofficial | Select-String -SimpleMatch $Name
  if ($existing) {
    choco source remove -n "$Name" | Out-Null
  }

  $addArgs = @("source","add","-n",$Name,"-s",$Url,"--priority","1")
  if ($User -and $Pass) {
    $addArgs += @("-u",$User,"-p",$Pass)
  }
  choco @addArgs | Out-Null
  Write-Host "Configured Chocolatey source '$Name' -> $Url"
}

function Get-PackageInstalledVersion {
  param([string]$Name)
  $line = choco list --local-only --exact --limit-output $Name 2>$null |
          Select-Object -First 1
  if (-not $line) { return $null }
  # Format: name|version
  ($line -split '\|')[1]
}

# ---- main ----
Ensure-Chocolatey
Ensure-ChocoSource -Name $SourceName -Url $SourceUrl -User $SourceUser -Pass $SourcePassword

$pkgHash = ConvertFrom-Json -InputObject $PackagesJson
foreach ($name in $pkgHash.Keys) {
  $want = [string]$pkgHash[$name]  # 'latest' or specific version
  if (-not $want -or $want -eq '' -or $want -eq 'latest') {
    $installed = Get-PackageInstalledVersion -Name $name
    if ($installed) {
      Write-Host "Upgrading $name to latest (currently $installed)..."
      choco upgrade $name -y --source "$SourceName"
    } else {
      Write-Host "Installing $name (latest)..."
      choco install $name -y --source "$SourceName"
    }
  } else {
    $installed = Get-PackageInstalledVersion -Name $name
    if ($installed -and ($installed -eq $want)) {
      Write-Host "$name $want already installed."
    } else {
      Write-Host "Installing $name $want..."
      choco install $name --version $want -y --source "$SourceName"
    }
  }
}
