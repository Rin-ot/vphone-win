# Install the WSL core from Microsoft's official GitHub release MSI.
# Needed when the inbox wsl.exe is only a stub and the Store route does not
# complete (both seen on the test machine). The Authenticode signature is
# verified before installing. Pin the version you want here.
$ErrorActionPreference = 'Stop'
$version = '3.0.5'
$file = "wsl.$version.0.x64.msi"
$work = Join-Path $env:USERPROFILE 'vphone-setup'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$msi = Join-Path $work $file
$log = Join-Path $work 'wsl-msi.log'
"[start] $(Get-Date -Format o)" | Out-File -FilePath $log -Encoding utf8
if (-not (Test-Path $msi)) {
  "downloading..." | Out-File -FilePath $log -Append -Encoding utf8
  Invoke-WebRequest -Uri "https://github.com/microsoft/WSL/releases/download/$version/$file" -OutFile $msi
}
"size=" + (Get-Item $msi).Length | Out-File -FilePath $log -Append -Encoding utf8
$sig = Get-AuthenticodeSignature $msi
"signature status=" + $sig.Status + " signer=" + $sig.SignerCertificate.Subject | Out-File -FilePath $log -Append -Encoding utf8
if ($sig.Status -ne 'Valid') { throw "signature not valid" }
"installing..." | Out-File -FilePath $log -Append -Encoding utf8
$installLog = Join-Path $work 'wsl-msi-install.log'
$p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart /log `"$installLog`"" -Wait -PassThru
"msiexec exit=" + $p.ExitCode | Out-File -FilePath $log -Append -Encoding utf8
"[done] $(Get-Date -Format o)" | Out-File -FilePath $log -Append -Encoding utf8
Write-Output "WSL installed (msiexec exit $($p.ExitCode)). Check with: wsl --version"
