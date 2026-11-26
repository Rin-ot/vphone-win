# vphone on Windows (WSL2) - setup guide & scripts

Run a **virtual iPhone** - iOS 26.6.2 on an iPhone 16 Pro profile - on a
Windows 11 PC, using [vphone-linux](https://github.com/YahiaAngelo/vphone-linux)
(YahiaAngelo's port of the vPhone QEMU machine to Linux) inside WSL2.

This repo is the Windows-side delta: the setup steps, resource tuning and
fixes needed on WSL that upstream's Linux instructions don't cover. It was
produced by actually doing the reproduction on a 16 GB laptop and fixing
everything that broke along the way (see `docs/TROUBLESHOOTING.md`).

> **Read this first.** This is an unofficial, experimental research project,
> not affiliated with Apple. Running iOS this way may conflict with Apple's
> license terms - check them and decide for yourself before proceeding.
> This repo contains **no Apple firmware or software**; the IPSW is
> downloaded from Apple by the upstream tooling during VM creation.

## Verified on (measured)

| | |
|---|---|
| Host | Windows 11 Education (build 26200), i7-13650HX (14C/20T) |
| RAM | 16 GB (the documented minimum - and it is tight, see below) |
| GPU | RTX 3050 Laptop - unused inside WSL; guest renders via lavapipe (CPU) |
| WSL | 3.0.5, Ubuntu **26.04** (24.04 lacks required library versions) |
| Guest | iPhone17,3 (iPhone 16 Pro) - iOS 26.6.2 (23G90), scale 1x |

Result: VM creation completed end to end; the guest boots to an unlocked
iOS home screen. Measured timings on this machine: IPSW download (10.5 GB)
~14 min; first-boot data migration ~14 min (after the tuning in step 6);
a normal boot to "up and unlocked" ~7 min.

> **Note:** the Ubuntu distro for WSL is a console-only (server) image -
> WSL has no desktop edition, and none is needed here. Every step runs in
> a terminal; the guest's screen is shown by QEMU's window (a WSLg app
> window on your Windows desktop) or captured through the screenshot RPC
> used in step 9.

## Procedure

Windows side (elevated PowerShell), in order:

1. `scripts/windows/01-enable-wsl-features.ps1` - enable WSL +
   VirtualMachinePlatform, then **reboot**. The script also places
   `.wslconfig` at `%UserProfile%\.wslconfig` (copied from
   `wslconfig.example`) if you do not have one yet.
2. Check `%UserProfile%\.wslconfig` and adjust it to your host.
   On a 16 GB host use `memory=14GB` - 12 GB measurably fails (see
   Troubleshooting #4). Leave ~2 GB for Windows.
3. `scripts/windows/02-install-wsl-msi.ps1` - install the WSL core from
   Microsoft's official GitHub MSI (signature-checked). Needed when the
   inbox `wsl.exe` is only a stub / the Store route stalls.
4. `scripts/windows/03-install-ubuntu.ps1` - Ubuntu-26.04, `--no-launch`.
5. `scripts/windows/04-init-ubuntu-user.ps1` - create the user, enable
   systemd, set the default user. Then `wsl --shutdown` once.

WSL side (Ubuntu):

6. Clone upstream and build:
   ```bash
   git clone https://github.com/YahiaAngelo/vphone-linux
   cd vphone-linux
   ./tools/check-host.sh        # run BEFORE setup: the dependency warnings
                                # (Rust, meson/ninja, lzfse, libxml2, usbip)
                                # are exactly what setup.sh installs next,
                                # so they are expected at this point. Only
                                # the RAM and /dev/shm warnings remain on a
                                # 16 GB host, and both are fine (see below).
   ./setup/setup.sh -y          # builds QEMU, vphone-cli, reims-vgpu, ...
   ```
   If the final `linux-apfs-rw` step fails, use `scripts/wsl/02-build-apfs.sh`
   (Troubleshooting #2), which finishes the build.
7. `scripts/wsl/01-fix-usbip.sh` - **before** creating the VM, or DFU attach
   fails silently (Troubleshooting #3).
8. Create the VM: `scripts/wsl/03-create-vm.sh` (wraps `create-vm.sh` with
   the shm remount, `SMP=8`, `WINDOW=0`). Downloads ~10.5 GB of IPSW and
   takes roughly an hour in total on this class of machine. If the first
   boot panics in data migration, just re-run it (Troubleshooting #4).
9. Start it headless and *see* it: `scripts/wsl/04-start-and-screenshot.sh`
   (starts with `--no-window`, unlocks, saves a screenshot via vphoned).
   Stop with `./setup/start-vm.sh --stop <name>`.
   The windowed `./setup/start-vm.sh <name>` also works, but if the window
   fails to initialize on your setup the VM stops with it - the headless
   route above is the reliable one (Troubleshooting #7).

## Layout

- `scripts/windows/` - PowerShell setup (feature enable, WSL MSI, Ubuntu, user init)
- `scripts/wsl/` - the four WSL-specific fixes/wrappers above
- `wslconfig.example` - tuned `.wslconfig` for a 16 GB host
- `docs/TROUBLESHOOTING.md` - every failure hit, its cause, and its fix

## Credits & license

All the hard parts are upstream: [vphone-linux](https://github.com/YahiaAngelo/vphone-linux)
and the original [vphone-cli](https://github.com/Lakr233/vphone-cli) research.
The scripts in this repo are MIT-licensed (see `LICENSE`); upstream keeps
its own license. iOS, iPhone and Apple are trademarks of Apple Inc.
