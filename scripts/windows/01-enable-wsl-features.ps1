# Enable the Windows features WSL2 needs. Run in an elevated PowerShell.
# A reboot is required afterwards (DISM exit code 3010 = success, restart needed).
$ErrorActionPreference = 'Continue'
$work = Join-Path $env:USERPROFILE 'vphone-setup'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$log = Join-Path $work 'enable-wsl.log'
"[start] $(Get-Date -Format o)" | Out-File -FilePath $log -Encoding utf8
"Enabling Microsoft-Windows-Subsystem-Linux..." | Out-File -FilePath $log -Append -Encoding utf8
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >> $log 2>&1
"DISM1 exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
"Enabling VirtualMachinePlatform..." | Out-File -FilePath $log -Append -Encoding utf8
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >> $log 2>&1
"DISM2 exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Out-String | Out-File -FilePath $log -Append -Encoding utf8
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Out-String | Out-File -FilePath $log -Append -Encoding utf8
"[done] $(Get-Date -Format o)" | Out-File -FilePath $log -Append -Encoding utf8
Write-Output "Done. Reboot Windows now, then continue with 02-install-wsl-msi.ps1 (log: $log)"
