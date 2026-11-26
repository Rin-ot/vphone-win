# Create the working user inside Ubuntu, enable systemd, and make the new
# user the default. Change $WslUser if you like (default: vphone).
param([string]$WslUser = 'vphone')
$ErrorActionPreference = 'Continue'
$work = Join-Path $env:USERPROFILE 'vphone-setup'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$log = Join-Path $work 'ubuntu-init.log'
"[start] $(Get-Date -Format o)" | Out-File -FilePath $log -Encoding utf8
"=== first boot as root ===" | Out-File -FilePath $log -Append -Encoding utf8
cmd /c "wsl -d Ubuntu-26.04 -u root -e bash -c ""cat /etc/os-release | head -3; id"" >> `"$log`" 2>&1"
"boot exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
"=== create user $WslUser ===" | Out-File -FilePath $log -Append -Encoding utf8
$inner = "id $WslUser 2>/dev/null || useradd -m -s /bin/bash $WslUser; usermod -aG sudo $WslUser; echo '$WslUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$WslUser; chmod 440 /etc/sudoers.d/$WslUser; printf '[boot]\nsystemd=true\n\n[user]\ndefault=$WslUser\n' > /etc/wsl.conf; cat /etc/wsl.conf"
cmd /c "wsl -d Ubuntu-26.04 -u root -e bash -c ""$inner"" >> `"$log`" 2>&1"
"user exit=$LASTEXITCODE" | Out-File -FilePath $log -Append -Encoding utf8
"[done] $(Get-Date -Format o)" | Out-File -FilePath $log -Append -Encoding utf8
Write-Output "Done (log: $log). Restart WSL (wsl --shutdown) so systemd and the default user take effect."
