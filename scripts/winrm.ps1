$adapter = Get-NetConnectionProfile -InterfaceAlias "*"
if ($adapter) {
    Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private
}

Enable-PSRemoting -Force
winrm quickconfig -q
Set-Service -Name "WinRM" -StartupType Automatic
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow
winrm enumerate winrm/config/listener
Restart-Service WinRM