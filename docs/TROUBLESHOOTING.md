# Troubleshooting - what actually broke on Windows/WSL, and the fixes

All of these were hit and fixed on the test machine (Windows 11, 16 GB RAM,
Ubuntu 26.04 under WSL 3.0.5). Upstream's own `docs/WSL.md` and
`docs/TROUBLESHOOTING.md` cover more; this file is only the delta.

## 1. `wsl.exe` is only a stub / the Store route never finishes
Symptom: `wsl --install` does not produce a working WSL.
Fix: install the WSL core from Microsoft's official GitHub release MSI and
verify the Authenticode signature first - `scripts/windows/02-install-wsl-msi.ps1`.

## 2. setup.sh fails at the very end building `linux-apfs-rw`
Cause: the build points at `/lib/modules/<wsl-kernel>/build`, which on
Ubuntu's WSL image is a stub headers directory with no usable Makefile.
Upstream's `tools/wsl-kernel-tree.sh` builds a real tree, but `setup.sh`
only uses it when that `/lib/modules/.../build` path does *not* exist -
and the stub is a busy mount, so it cannot be moved aside either.
Fix: build the module manually against the self-built tree -
`scripts/wsl/02-build-apfs.sh`. Check `vermagic` matches `uname -r`.

## 3. create-vm: "The device did not enter dfu/recovery mode in time"
The guest *was* in DFU; the attach never happened. Ubuntu's
`/usr/bin/usbip` is a wrapper that execs
`/usr/lib/linux-tools/$(uname -r)/usbip`, which does not exist for the WSL
kernel, and the auto-attach loop suppresses stderr - so every call failed
silently. Fix: symlink a real binary into the per-kernel path -
`scripts/wsl/01-fix-usbip.sh`.

## 4. First boot: datamigrator watchdog panic, over and over
iOS kills first-boot data migration (`datamigratorhelper` userspace panic)
when the guest is too slow. On the test machine it panicked at ~17-27 min
with WSL at 12 GB / guest SMP=6: QEMU's footprint (~11.3 GB RSS) exceeded
WSL's RAM and swap thrashing slowed emulation below the watchdog's pace.
Fix: `.wslconfig` memory 14 GB (on a 16 GB host) and `SMP=8` - migration
then finished in ~14 minutes. The panic is not fatal to the VM: stop QEMU
(`tools/dfu-stop.sh`) and re-run `create-vm.sh`; it resumes at the boot step.

## 5. `/dev/shm` too small for the guest
Guest RAM (8 GB by default) lives in `/dev/shm`, which WSL sizes at half of
WSL's memory (~6-7 GB). Remount before starting/creating:
`sudo mount -o remount,size=12G /dev/shm`

## 6. CFW install hangs silently
Seen once: the guest serial went quiet and create-vm's helper shells became
zombies. Recovery (as upstream documents): kill the create-vm tree, run
`tools/dfu-stop.sh`, unmount stale sshfs mounts
(`fusermount3 -u /var/tmp/vphone-cfw.*`), re-run `create-vm.sh`. It resumed
and completed.

## 7. The window helper can take QEMU down with it
With the window enabled, QEMU exits when the GTK window helper dies
(serial.log ends with `vphone-window: window closed the control socket`).
If the window cannot initialize on your setup (for example the
libdecor-gtk plugin fails to load), the VM stops with it.
Fix: run headless - `start-vm.sh --no-window` - and verify visually with
vphoned's `screen.screenshot` RPC (`scripts/wsl/04-start-and-screenshot.sh`).

## 8. Closing the launching session stops the VM
QEMU started by `start-vm.sh` belongs to the WSL session that launched it;
when that session ends, the VM is stopped with it. Keep the terminal (or a
holder process such as a `sleep` loop in the same session) open for as
long as the VM must run.

## 9. Final verify step times out (`script.eval ... 30 seconds`)
Once, create-vm's last check timed out at 30 s *after* vphoned had already
confirmed `data_migration_done: true`. The migration result is persisted -
just re-run `create-vm.sh`; the plain (non-migrating) boot verifies fast.

## 10. Small print
- The guest clock resets to America/Los_Angeles (tzinit default) - set the
  guest's time zone in iOS Settings if you care.
- "warning: / stayed read-only, so no 1x boot logo was written" is cosmetic.
- Networking and audio inside the guest are upstream-untested; this setup
  verifies boot, unlock, rendering and screenshots only.

## 11. apt cannot reach the Ubuntu archives on a restricted network
Symptom: `setup.sh` dies at the package step - every fetch from
archive.ubuntu.com / security.ubuntu.com times out (IPv6 "Network is
unreachable", IPv4 "connection timed out") - and the run then ends with a
misleading "this release has no clang lld ninja-build ..." error. The
release is fine; apt simply downloaded nothing.
Cause: the network blocks direct egress (proxy-only LANs, or port 80
blocked while 443 is allowed). WSL does not inherit Windows' proxy
settings, and DNS resolving correctly does not mean traffic can leave.
Diagnose inside WSL:
```bash
curl -sI https://archive.ubuntu.com/ubuntu/ | head -1   # port 443 test
```
Fixes, depending on the result:
- **443 answers:** switch apt to HTTPS sources and re-run setup.sh:
  ```bash
  sudo sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g; s|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources
  sudo apt update
  ```
  The later downloads (rustup, GitHub, the IPSW) are all HTTPS too.
- **443 also times out:** the LAN is proxy-only. Take the proxy host:port
  from Windows' proxy settings and give it to apt persistently:
  ```bash
  echo 'Acquire::http::Proxy "http://PROXY:PORT"; Acquire::https::Proxy "http://PROXY:PORT";' | sudo tee /etc/apt/apt.conf.d/95proxy
  export http_proxy=http://PROXY:PORT https_proxy=http://PROXY:PORT   # for git/curl/rustup in your shell
  ```
