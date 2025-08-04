# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

#
# install.ps1
#
<#
.SYNOPSIS

    Extract the bundle into Ec2Launch file path.

.DESCRIPTION

.EXAMPLE

    ./install

#>

# Required for powershell to determine what parameter set to use when running with zero args (us a non existent set name)
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
  # Allows EC2Launch to send telemetry to AWS.
  # Disable telemetry by installing with -EnableTelemetry:$false.
  [Parameter(Mandatory = $false,ParameterSetName = "Schedule")]
  [switch]$EnableTelemetry = $true
)

$sourcePath = Join-Path $PSScriptRoot -ChildPath "EC2-Windows-Launch.zip"
$destPath = Join-Path $env:programData -ChildPath "Amazon\EC2-Windows\Launch"
$moduleScriptsFilePath = Join-Path $destPath -ChildPath "Module\Scripts"
Set-Variable TelemetryEnvVar -Option Constant -Scope Local -Value "EC2LAUNCH_TELEMETRY"

# Check if source package exists in current location
if (-not (Test-Path $sourcePath))
{
  Write-Host ("{0} is not found.. exit!" -f $sourcePath)
  exit 1
}

$telemetryEnvVarValue = "0"
if ($EnableTelemetry)
{
  $telemetryEnvVarValue = "1"
}
[Environment]::SetEnvironmentVariable($TelemetryEnvVar,$telemetryEnvVarValue,'Machine')

# Check if Ec2Launch is already installed
if (Test-Path $destPath)
{
  Remove-Item -Path $destPath -Recurse -Force -Confirm:$false
}

$unpacked = $false;
if ($PSVersionTable.PSVersion.Major -ge 5)
{
  try
  {
    # Nano doesn't support Expand-Archive yet, but plans to add it in future release.
    # Attempt to execute Expand-Archive to unzip the source package first.
    Expand-Archive $sourcePath -DestinationPath $destPath -Force

    # Set this TRUE to indicate the unpack is done
    $unpacked = $true;

    Write-Host ("Successfully extract files to {0}" -f $destPath)
  }
  catch
  {
    Write-Host "Failed to extract files by Expand-Archive cmdlet.."
  }
}

# If unpack failed with Expand-Archive cmdlet, try it with [System.IO.Compression.ZipFile]::ExtractToDirectory
if (-not $unpacked)
{
  Write-Host "Attempting it again with [System.IO.Compression.ZipFile]::ExtractToDirectory"

  try
  {
    # Load [System.IO.Compression.FileSystem]
    Add-Type -AssemblyName System.IO.Compression.FileSystem
  }
  catch
  {
    # If failed, try to load [System.IO.Compression.ZipFile]
    Add-Type -AssemblyName System.IO.Compression.ZipFile
  }

  try
  {
    # Try to unpack the package by [System.IO.Compression.ZipFile]::ExtractToDirectory and move them to destination
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$sourcePath","$destPath")
    Write-Host ("Successfully extract files to {0}" -f $destPath)
  }
  catch
  {
    Write-Host "Failed to extract the files.. exit!"
    exit 1
  }
}

try
{
  # Disable inheritance of the folder from ProgramData
  $ACL = Get-Acl -Path $moduleScriptsFilePath
  $ACL.SetAccessRuleProtection($true,$true)
  $ACL | Set-Acl -Path $moduleScriptsFilePath

  # Remove access for normal users to create files in the folder
  $ACL = Get-Acl -Path $moduleScriptsFilePath
  $BuiltinUsersSID = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-545'
  $AllowCreateFileAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule (
    $BuiltinUsersSID,
    [System.Security.AccessControl.FileSystemRights]::CreateFiles,
    [System.Security.AccessControl.AccessControlType]::Allow
  )
  $ACL.RemoveAccessRule($AllowCreateFileAccessRule)
  $ACL | Set-Acl -Path $moduleScriptsFilePath
}
catch
{
  Write-Host "Failed to update user permissions for module scripts"
  exit 1
}

# Add a shortcut to the Settings UI
$settingsPath = Join-Path $destPath -ChildPath "Settings"
if (-not (Test-Path $settingsPath))
{
  Write-Host "Failed to find Settings folder after installation"
  exit 1
}

$shortcutTargetPath = Join-Path $settingsPath -ChildPath "Ec2LaunchSettings.exe"
if (-not (Test-Path $shortcutTargetPath))
{
  Write-Host "Failed to find EC2Launch Settings UI after installation"
  exit 1
}

$shortcutDirPath = Join-Path $env:programData -ChildPath "Microsoft\Windows\Start Menu\Programs"
if (-not (Test-Path $shortcutDirPath))
{
  $shortcutDirPath = Join-Path $env:userProfile -ChildPath "Start Menu\Programs"
  if (-not (Test-Path $shortcutDirPath))
  {
    Write-Host "Failed to select a Windows shortcut directory"
    exit 1
  }
}

try
{
  $shortcutPath = Join-Path $shortcutDirPath -ChildPath "Ec2LaunchSettings.lnk"
  $wshShell = New-Object -ComObject WScript.Shell
  $shortcut = $WshShell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $shortcutTargetPath
  $shortcut.Save()
}
catch
{
  Write-Host "Failed to create shortcut to the Settings UI"
  exit 1
}

# SIG # Begin signature block
# MIIm0wYJKoZIhvcNAQcCoIImxDCCJsACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCdJcNs1zL1Bei7
# G5RY4JbdjCO1YHA80KXFF9Kc1tQh6aCCDlUwggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggedMIIFhaADAgECAhABe4J3F0ijMMT66O5gzQEfMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjExMjI4MDAwMDAwWhcNMjMwMTAz
# MjM1OTU5WjCB8jEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xEzARBgsr
# BgEEAYI3PAIBAxMCVVMxGTAXBgsrBgEEAYI3PAIBAhMIRGVsYXdhcmUxEDAOBgNV
# BAUTBzQxNTI5NTQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdTZWF0dGxlMSIwIAYDVQQKExlBbWF6b24gV2ViIFNlcnZpY2VzLCBJ
# bmMuMRMwEQYDVQQLEwpBbWF6b24gRUMyMSIwIAYDVQQDExlBbWF6b24gV2ViIFNl
# cnZpY2VzLCBJbmMuMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAtCrQ
# u3fd3L+RmFVifX8P7XsFoqdsNC6J9Gnnw9tIzGwRU5ke3UKljLvIMed9kvTZ196W
# JZf/GT6WJIbq2QVRHBFrNzQ24vOtdDJp4vEJN2zTWNoMx2IMrP3u7Arlh8BEuORU
# faeZjTFrxG1ZOn2BG8RcaeST+YINZoM6F+tPEzEg7UPbCe6yu1Wztkzj1nadwO9J
# A0vPHLsldeSgo5bqXS3KgTkUZQXgNyB7+DtgjFH+slV1CfzA5B20O3CuZq916q7s
# 1XaVjtCirDjDXIqeULzLUd6F4gvcHCtPIsPLm9q9vNn9Z7YTXcfbTfIMI/Q5OQKF
# i2f5LTEAYwMuQC963rAqSamLxs8u6EMHentmXPpTN7T/iMSRXMsDMn61XCDwkJG0
# IAkyzjfL8NgBn0kc5VZTztnstjwoWvTWHTXUXDPtyIg12vfg5hzLdc1GJhqt1AVA
# DDgp4d/k0tvICm1UQMoHqGrZ59zIWEBHq3aNdIiAl2ckMiLYsaf5Tn+FmvRdAgMB
# AAGjggI1MIICMTAfBgNVHSMEGDAWgBRoN+Drtjv4XxGG+/5hewiIZfROQjAdBgNV
# HQ4EFgQUsPO2uKK+TDLSX5Ez4DXbRIGMdIkwLgYDVR0RBCcwJaAjBggrBgEFBQcI
# A6AXMBUME1VTLURFTEFXQVJFLTQxNTI5NTQwDgYDVR0PAQH/BAQDAgeAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMIG1BgNVHR8Ega0wgaowU6BRoE+GTWh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5
# NlNIQTM4NDIwMjFDQTEuY3JsMFOgUaBPhk1odHRwOi8vY3JsNC5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIx
# Q0ExLmNybDA9BgNVHSAENjA0MDIGBWeBDAEDMCkwJwYIKwYBBQUHAgEWG2h0dHA6
# Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCBlAYIKwYBBQUHAQEEgYcwgYQwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggrBgEFBQcwAoZQaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNp
# Z25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAgEAOLIzfXbFw3b1+5oTm9q/ovV5uSCa26vf0QR+auJmfcaZ
# 24S2C3Mlc/TQ9NEodiJd8SJdNGlpGObtQdzi61ykbUGcxR6i4YI8kZ4WerMr5fCd
# 4NGRToXmn7ZC9qxhHoMRDOH59W+NY4XkouE79XfQgnNjwVyAorb0oSJ94DS0eBAk
# S5Z/aNHeoHSND7CL/BGMKZIfy5oeQudafNOM8dyt9hAqJf+nOrpvOwlLpJgXTYNH
# eGxP4cyb3EQTDMrXYxHckSi4usUq1iW5pCdPA/pQt5BNmGoB0azVdA73Vym/UyR5
# vIz+v1OAWaPdvRvm/26hGyr+WzsR6WIzIBg2GB9k0uv+1bKdqL0yu1gNmcV8LZHR
# LNTMx1DX85RKjXNcHcQYjDH2R5oy0CHmV7QSwFJAc2a4+h+7TcmZsbdKlPHi6bFW
# /G5HDPWt/F9oQ3OZknWdTigo4vuYl7jcpoSMZgBVGv9EXTrpkLaoCxBn48i7UJ8O
# gZzskxcjBx9dObtu9kEA1IndCHoqiqFGakdYI2+LjIr+cPT58XvMQjm7sfeeTTTy
# +amZ+ONAscTa1y8jOHIycnMZSKjh/OGw0iApuTUREPB68c6tdsjODU5GF8u5k28M
# QVuSQzZbKN+t8FyPh2F4HT9tfvTJxSJxArh/YiXqyyjc/B5AIpwxMIHyw22EzbYx
# ghfUMIIX0AIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTECEAF7gncXSKMwxPro7mDNAR8wDQYJYIZI
# AWUDBAIBBQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQg+knBy+EDmRnyuWVbB7KWQplMrsorkBQIha1Rzvm64+swDQYJKoZIhvcN
# AQEBBQAEggGALL8CEjjvUg2BIzB0LE2QLNuefLgfeCFAJTZhYK5YP8mUXjkPDKcv
# gXkeQUPWvV2j+RM7aADjMsmiEqlhdl+/c8J7jX2Fvb+/zxSbA9ybLB1jNsKs+I8/
# N7JQQmKjwpUOHTtm8JohR8aNdBhEXBfMIIVnSWD7Gm1ncVZjSRiw+BNwfBROaiXy
# 8gZ18zH2NRwuDku13DwRedFXR2Nn5q3MW8RS8TK9yTrU1mgkaXNKYQ7z/jHwtMJr
# t8If4jqF3B7CLJBwe1zL7rmtDxcixLrVfufcHaq0VkFLomI2K1EoLwJ7MDVQRpMt
# WC90dkXw8/Nv62tqXUFxLlCvJ+VpV/S5v+qsMMg84wyGkhnm5/0r5OrWtZOI0wzE
# d2WfoDaPdjaeaI6oyfxcAxnf8oPjmnDQP3WtkCKu+QJs95jmjmjE9UdpC8CSy6NL
# buz7ndJGRqh5qjjgoH5NMdAVo3B4DOzlSs4bmgUN+0aMp6w/YZPOd/NHuxfNFsiG
# jgQy7wy/kOpWoYIVKjCCFSYGCisGAQQBgjcDAwExghUWMIIVEgYJKoZIhvcNAQcC
# oIIVAzCCFP8CAQMxDTALBglghkgBZQMEAgEwgfMGCyqGSIb3DQEJEAEEoIHjBIHg
# MIHdAgEBBgpghkgBhvpsCgMFMDEwDQYJYIZIAWUDBAIBBQAEINHzASurFdYLmbhf
# Ww+WDq0LNrKykc9Jzt6nvMFjWiPHAggceKVL+jJTYxgPMjAyMjA2MTcxOTA3MzFa
# MAMCAQGgeaR3MHUxCzAJBgNVBAYTAkNBMRAwDgYDVQQIEwdPbnRhcmlvMQ8wDQYD
# VQQHEwZPdHRhd2ExFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKzApBgNVBAMTIkVu
# dHJ1c3QgVGltZXN0YW1wIEF1dGhvcml0eSAtIFRTQTGggg9VMIIEKjCCAxKgAwIB
# AgIEOGPe+DANBgkqhkiG9w0BAQUFADCBtDEUMBIGA1UEChMLRW50cnVzdC5uZXQx
# QDA+BgNVBAsUN3d3dy5lbnRydXN0Lm5ldC9DUFNfMjA0OCBpbmNvcnAuIGJ5IHJl
# Zi4gKGxpbWl0cyBsaWFiLikxJTAjBgNVBAsTHChjKSAxOTk5IEVudHJ1c3QubmV0
# IExpbWl0ZWQxMzAxBgNVBAMTKkVudHJ1c3QubmV0IENlcnRpZmljYXRpb24gQXV0
# aG9yaXR5ICgyMDQ4KTAeFw05OTEyMjQxNzUwNTFaFw0yOTA3MjQxNDE1MTJaMIG0
# MRQwEgYDVQQKEwtFbnRydXN0Lm5ldDFAMD4GA1UECxQ3d3d3LmVudHJ1c3QubmV0
# L0NQU18yMDQ4IGluY29ycC4gYnkgcmVmLiAobGltaXRzIGxpYWIuKTElMCMGA1UE
# CxMcKGMpIDE5OTkgRW50cnVzdC5uZXQgTGltaXRlZDEzMDEGA1UEAxMqRW50cnVz
# dC5uZXQgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgKDIwNDgpMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEArU1LqRKGsuqjIAcVFmQqK0vRvwtKTY7tgHal
# Z7d4QMBzQshowNtTK91euHaYNZOLGp18EzoOH1u3Hs/lJBQesYGpjX24zGtLA/EC
# DNyrpUAkAH90lKGdCCmziAv1h3edVc3kw37XamSrhRSGlVuXMlBvPci6Zgzj/L24
# ScF2iUkZ/cCovYmjZy/Gn7xxGWC4LeksyZB2ZnuU4q941mVTXTzWnLLPKQP5L6RQ
# stRIzgUyVYr9smRMDuSYB3Xbf9+5CFVghTAp+XtIpGmG4zU/HoZdenoVve8AjhUi
# VBcAkCaTvA5JaJG/+EfTnZVCwQ5N328mz8MYIWJmQ3DW1cAH4QIDAQABo0IwQDAO
# BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUVeSB0RGA
# vtiJuQijMfmhJAkWuXAwDQYJKoZIhvcNAQEFBQADggEBADubj1abMOdTmXx6eadN
# l9cZlZD7Bh/KM3xGY4+WZiT6QBshJ8rmcnPyT/4xmf3IDExoU8aAghOY+rat2l09
# 8c5u9hURlIIM7j+VrxGrD9cv3h8Dj1csHsm7mhpElesYT6YfzX1XEC+bBAlahLVu
# 2B064dae0Wx5XnkcFMXj0EyTO2U87d89vqbllRrDtRnDvV5bu/8j72gZyxKTJ1wD
# LW8w0B62GqzeWvfRqqgnpv55gcR5mTNXuhKwqeBCbJPKVt7+bYQLCIt+jerXmCHG
# 8+c8eS9enNFMFY3h7CI3zJpDC5fcgJCNs2ebb0gIFVbPv/ErfF6adulZkMV8gzUR
# ZVEwggUTMIID+6ADAgECAgxY2hP/AAAAAFHODfcwDQYJKoZIhvcNAQELBQAwgbQx
# FDASBgNVBAoTC0VudHJ1c3QubmV0MUAwPgYDVQQLFDd3d3cuZW50cnVzdC5uZXQv
# Q1BTXzIwNDggaW5jb3JwLiBieSByZWYuIChsaW1pdHMgbGlhYi4pMSUwIwYDVQQL
# ExwoYykgMTk5OSBFbnRydXN0Lm5ldCBMaW1pdGVkMTMwMQYDVQQDEypFbnRydXN0
# Lm5ldCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAoMjA0OCkwHhcNMTUwNzIyMTkw
# MjU0WhcNMjkwNjIyMTkzMjU0WjCBsjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVu
# dHJ1c3QsIEluYy4xKDAmBgNVBAsTH1NlZSB3d3cuZW50cnVzdC5uZXQvbGVnYWwt
# dGVybXMxOTA3BgNVBAsTMChjKSAyMDE1IEVudHJ1c3QsIEluYy4gLSBmb3IgYXV0
# aG9yaXplZCB1c2Ugb25seTEmMCQGA1UEAxMdRW50cnVzdCBUaW1lc3RhbXBpbmcg
# Q0EgLSBUUzEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDZI+YUpOh8
# S4VxWPv4geZyi11Gw4gAHzjQiuHWblYw5a/aZFB9whM5+71mtNqE+4PQKB/Lduhg
# UGmb885PE+LBPsHfEssyo/heRCIOzDrpjUm5YHTI3lQ9QV5DXyhGqaa3yhArIrxb
# TVuMF2UShv0sd9XFoIzKwoPgR1d853CuYkUnMRgK1MCkGFVS92DGBEuz3WgybhAf
# NBG4Enhk8e6p4PfjsSKPNFply4r04UVQdN+Tl6Y05tBMO583SVKnU06fLmdc7Zb8
# pb90UYjjqo692bEvX1AwFvRRYCJrmcv/4VQ7uftEOKUIOSObaUf6PMTQ56rfRrLs
# 8ooZrCmyOJV1AgMBAAGjggEjMIIBHzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
# DwEB/wQEAwIBBjA7BgNVHSAENDAyMDAGBFUdIAAwKDAmBggrBgEFBQcCARYaaHR0
# cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwMwYIKwYBBQUHAQEEJzAlMCMGCCsGAQUF
# BzABhhdodHRwOi8vb2NzcC5lbnRydXN0Lm5ldDAyBgNVHR8EKzApMCegJaAjhiFo
# dHRwOi8vY3JsLmVudHJ1c3QubmV0LzIwNDhjYS5jcmwwEwYDVR0lBAwwCgYIKwYB
# BQUHAwgwHQYDVR0OBBYEFMPCcdJ712gFrjs5mzQlDGIDx1doMB8GA1UdIwQYMBaA
# FFXkgdERgL7YibkIozH5oSQJFrlwMA0GCSqGSIb3DQEBCwUAA4IBAQAdJOeadFuq
# cPyxDjFF1ywAf2Y6K6CaNKqsY22J+Z/fDXf9JCP8T5y3b4/z9B+2wf3WHMSMiGbB
# Y426V3fTuBoeyFGtzGA2GodqKOoRZd7MPCyMdLfoUEPTzCjoFWwRKp8UlSnJBVe1
# ZzboPKmD70HBIRbTfvctEUdmdmCCEmmMdlVzD98vS13pbCP4B/a1fdZpRZxYfWEu
# /HhLQ06JkUZELKBTqEWh9hZYu5ET8kvF3wvA564per1Fs+dwMOc0jut69tO10d5r
# E5lGs4vSTZN1tfFvv9wAKMIlv7zno2U07D8NHZeM+qqIIqQYNdsFjnbjEMgpj2PQ
# rqwY2drEn1ESMIIGDDCCBPSgAwIBAgIRAI3OFfOnlMWHAAAAAFWSM/QwDQYJKoZI
# hvcNAQELBQAwgbIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1FbnRydXN0LCBJbmMu
# MSgwJgYDVQQLEx9TZWUgd3d3LmVudHJ1c3QubmV0L2xlZ2FsLXRlcm1zMTkwNwYD
# VQQLEzAoYykgMjAxNSBFbnRydXN0LCBJbmMuIC0gZm9yIGF1dGhvcml6ZWQgdXNl
# IG9ubHkxJjAkBgNVBAMTHUVudHJ1c3QgVGltZXN0YW1waW5nIENBIC0gVFMxMB4X
# DTIwMDcyMjE1MzMyOVoXDTMwMTIyOTE2MjkyM1owdTELMAkGA1UEBhMCQ0ExEDAO
# BgNVBAgTB09udGFyaW8xDzANBgNVBAcTBk90dGF3YTEWMBQGA1UEChMNRW50cnVz
# dCwgSW5jLjErMCkGA1UEAxMiRW50cnVzdCBUaW1lc3RhbXAgQXV0aG9yaXR5IC0g
# VFNBMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMo+7CRi4ff+39E2
# qTdm1nkXFJRCAKSGl7gnjOtPqffTruKrMAQIKF+bU6aHii3dAlJftbjltlDwnKsS
# we4aVniKbkQ/qYqP19tT2cZHyAzcRlcAZwYXGoW3QKqvdgfnkF+UktWu1tfNeaHF
# NStEhF9JHNVzuIGNcpQCaqnPVpKqNpTDUMlWl4hc4X9f/fvfFI49qyQN9nuPavpu
# HvqVvX2Q+ORCFL9VXgRUkzFD98PnwgURaKxAaccjN+xaTCnJ3zWzfklOxnrbzsIl
# lJ43P4jsJE05j3/vFWtUTHHxDSF8WnXQh1OJoFvgHfucB8CoobQi0GKkxxd/N07O
# LTpY4+XwJoZNQgefvqPiGaJrcqVGv8tkWyXIRfTe6Dy2/ZzzoO+DQXw2cJDDUmKw
# x389e+WWh6VW/w7qSQXftN0Tb0XTm8gjeSowmZ2Z3MzNpS6BU1Ii8tA9ojdSkZFG
# cNbFSwX/TvTcZAaX/nyQhievnzRVSImrIsB1B4wh2QTTHKfqbaTJUivixAKJMF7n
# mzHmOWWtca3vZ1vcoyTtDebiqXo6GFXe8EYuNE0aTZiADU7RbIV1uAPCANUiSibR
# jt3ttdQn1jp8Z2mG11Q/l89kvpGrbradGRB5tZcO9NGFyeSux8C0qgfEH8E6V5/N
# DqZ65RWGsqr0opMsz4z3UfrdjNBJAgMBAAGjggFXMIIBUzAOBgNVHQ8BAf8EBAMC
# B4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQQYDVR0gBDowODA2BgpghkgBhvps
# CgMFMCgwJgYIKwYBBQUHAgEWGmh0dHA6Ly93d3cuZW50cnVzdC5uZXQvcnBhMAkG
# A1UdEwQCMAAwaAYIKwYBBQUHAQEEXDBaMCMGCCsGAQUFBzABhhdodHRwOi8vb2Nz
# cC5lbnRydXN0Lm5ldDAzBggrBgEFBQcwAoYnaHR0cDovL2FpYS5lbnRydXN0Lm5l
# dC90czEtY2hhaW4yNTYuY2VyMDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwu
# ZW50cnVzdC5uZXQvdHMxY2EuY3JsMB8GA1UdIwQYMBaAFMPCcdJ712gFrjs5mzQl
# DGIDx1doMB0GA1UdDgQWBBQtVoDvjvdKQxxDobXe2deoqmsmKDANBgkqhkiG9w0B
# AQsFAAOCAQEAWEvO2P6B11HYx1yNktJOlR6FhkPt4BrmmiFCM13jkb74UHx2jCWp
# QdSEmejooraZl2iiIL0yqKopfAp2Gp/IVY6r03vU435ZfpJwOQ/t9i/zT/90XPPn
# MDRAoxGja3KkMhEFfP2Ri0eoVzZSx/q1RYTRsj5C5RZe3QPTqf09cGd62hPghIJn
# OGBWw62wiOEKN35igQa7IwTvWKAjqNEJYzDN2Rk49Otad1i+X7/rlC3/LwQwZBCP
# PllWLjo2Tw48lg+Pyep+f0kyH6Nfbtoin9fZFzlZ3kgXegJLWHH/twwtofBnoxHc
# 98m82R7LbAwVJ3hIFmss8a2XuHVsu5XDjjGCBJowggSWAgEBMIHIMIGyMQswCQYD
# VQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEoMCYGA1UECxMfU2VlIHd3
# dy5lbnRydXN0Lm5ldC9sZWdhbC10ZXJtczE5MDcGA1UECxMwKGMpIDIwMTUgRW50
# cnVzdCwgSW5jLiAtIGZvciBhdXRob3JpemVkIHVzZSBvbmx5MSYwJAYDVQQDEx1F
# bnRydXN0IFRpbWVzdGFtcGluZyBDQSAtIFRTMQIRAI3OFfOnlMWHAAAAAFWSM/Qw
# CwYJYIZIAWUDBAIBoIIBpjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJ
# KoZIhvcNAQkFMQ8XDTIyMDYxNzE5MDczMVowKQYJKoZIhvcNAQk0MRwwGjALBglg
# hkgBZQMEAgGhCwYJKoZIhvcNAQELMC8GCSqGSIb3DQEJBDEiBCC5F97dWbxiTC5i
# zZStUEMYGa90hgbavXB2KrBBv6x9fjCCAQwGCyqGSIb3DQEJEAIvMYH8MIH5MIH2
# MIHzBCCVCib9x8AgGOn3kalcOPJu7z2kMmfKsM0VpVWvYxByyTCBzjCBuKSBtTCB
# sjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xKDAmBgNVBAsT
# H1NlZSB3d3cuZW50cnVzdC5uZXQvbGVnYWwtdGVybXMxOTA3BgNVBAsTMChjKSAy
# MDE1IEVudHJ1c3QsIEluYy4gLSBmb3IgYXV0aG9yaXplZCB1c2Ugb25seTEmMCQG
# A1UEAxMdRW50cnVzdCBUaW1lc3RhbXBpbmcgQ0EgLSBUUzECEQCNzhXzp5TFhwAA
# AABVkjP0MAsGCSqGSIb3DQEBCwSCAgCu/CAKgvTAuFuHt9Nxg90UqvCMi4jGWGM7
# kBmBkAwHlqbL2pBD+rozw0AHyu+yz4T3bflrv54mBzMI/+3bHkZ2G9pLTfLov3ld
# 5clkCBoPa6NpncK+7tWRD1gcEpx6M/Lv6aM3eLuhoXHcq72ectgB1hXIsa9fkIDQ
# I38TXfR2ZJHW0ypOzDUW085nh5HHiWdjWxhTDLOx+N90oaLDTmVXJaifrBikNqQQ
# xoEOv0xZ/OE9AuaqzlBKa9Yh3UMFebY+KSOuJCH89WvsakvNmFG/BUyOCtplJooE
# 9uoEdGtnZYwMRFAkePdnWEZ6GjMokZmFpKql7CVp+vtbchMO281YeTExhgs9S/6Y
# aFLI+oQEZDREJv0g+EVeuQmDY3r5z68TfhMyKuokPNxO6DNdudWEMAY/1IJnwKYG
# 06diNG0EYmEBgBF8/myM+f8Y5RYgKLvX30NKZNXpqSGGnxuYlM9p/tkwefo7baw7
# 4oXp7pyaqWkOW2zKhsfp+E4K9BX9iu73aAG3JiO6FPnxmjQrdnRGfO44BsFdKB08
# kLZP4ReBeMu8kCu062NkLtDWG6Mt80iLloazd08Rq1GWQZ+XuZxXq8Ei7GGju9O+
# DvwPbhYXnfQVQdtDYc1kjXvHUMF98Q+791qxAVtLJrp6ZDq7PFz85Q4A/D+mTjtu
# g5vVSSHbzg==
# SIG # End signature block
