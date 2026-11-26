# Install Ubuntu 26.04 without launching it (first launch would block on the
# interactive user-creation prompt). Ubuntu 24.04 does NOT work: it lacks
# libimobiledevice-glue / libtatsu versions vphone-linux needs.
$ErrorActionPreference = 'Continue'
$work = Join-Path $env:USERPROFILE 'vphone-setup'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$log = Join-Path $work 'ubuntu-install.log'
"[start] $(Get-Date -Format o)" | Out-File -FilePath $log -Encoding utf8
cmd /c "wsl --install -d Ubuntu-26.04 --no-launch >> `"$log`" 2>&1"
"install exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
cmd /c "wsl --list --verbose >> `"$log`" 2>&1"
"[done] $(Get-Date -Format o)" | Out-File -FilePath $log -Append -Encoding utf8
Write-Output "Done (log: $log). Continue with 04-init-ubuntu-user.ps1"
