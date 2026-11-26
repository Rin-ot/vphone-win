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
# Place .wslconfig now (README step 2), before any distro is installed:
# WSL reads it when its VM starts. An existing .wslconfig is left untouched.
$wslExample = Join-Path $PSScriptRoot '..\..\wslconfig.example'
$wslTarget = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path $wslTarget) {
  ".wslconfig already exists at $wslTarget - left as-is" | Out-File -FilePath $log -Append -Encoding utf8
} elseif (Test-Path $wslExample) {
  Copy-Item $wslExample $wslTarget
  ".wslconfig placed at $wslTarget (from wslconfig.example)" | Out-File -FilePath $log -Append -Encoding utf8
} else {
  "wslconfig.example not found next to this script - copy it to $wslTarget manually" | Out-File -FilePath $log -Append -Encoding utf8
}
"[done] $(Get-Date -Format o)" | Out-File -FilePath $log -Append -Encoding utf8
Write-Output "Done. Reboot Windows now, then continue with 02-install-wsl-msi.ps1 (log: $log)"
