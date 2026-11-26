#!/usr/bin/env bash
# Fix: setup.sh's last step (linux-apfs-rw kernel module) fails on WSL.
# setup.sh only uses the self-built kernel tree when /lib/modules/<rel>/build
# does NOT exist, but Ubuntu's WSL image ships a stub headers directory at
# exactly that path (and it is a busy mount, so it cannot be moved aside).
# Workaround: run the upstream kernel-tree builder, then build the module
# manually with the same variables setup.sh would have used.
# Run inside the vphone-linux checkout, AFTER a setup.sh run got everything
# else built (the failure is only the final apfs step).
set -euo pipefail
cd "${VPHONE_LINUX_DIR:-$HOME/vphone-linux}"
rel=$(uname -r)
if [ ! -d ".build/wsl-kernel-$rel" ]; then
  ./tools/wsl-kernel-tree.sh
fi
make -C .build/linux-apfs-rw CC=gcc-13 KERNEL_DIR="$PWD/.build/wsl-kernel-$rel"
ls -la .build/linux-apfs-rw/apfs.ko
modinfo .build/linux-apfs-rw/apfs.ko | grep -E 'vermagic' || true
echo "vermagic must match: $rel"
# Finish with ONLY the release phase. Do NOT re-run the full setup.sh:
# its build phase re-enters build_apfs, points at the stub headers again
# and fails the same way, even though apfs.ko is already built.
./setup/setup.sh release -y
