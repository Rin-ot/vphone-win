#!/usr/bin/env bash
# Fix: on WSL, /usr/bin/usbip is a wrapper that execs
# /usr/lib/linux-tools/$(uname -r)/usbip - which does not exist for the
# Microsoft WSL kernel, so every usbip call in vphone-linux's
# usbip-autoattach.sh fails SILENTLY and the guest never gets attached in
# DFU mode ("The device did not enter dfu/recovery mode in time").
# Point the per-kernel path at a real usbip binary from the installed
# linux-tools package.
set -euo pipefail
rel=$(uname -r)
target_dir="/usr/lib/linux-tools/$rel"
if [ -x "$target_dir/usbip" ]; then
  echo "usbip already present at $target_dir/usbip"
  exit 0
fi
real=$(ls /usr/lib/linux-tools/*/usbip 2>/dev/null | head -1 || true)
[ -n "$real" ] || { echo "no real usbip binary found - install linux-tools-generic first" >&2; exit 1; }
echo "linking $target_dir/usbip -> $real"
sudo mkdir -p "$target_dir"
sudo ln -sf "$real" "$target_dir/usbip"
usbip version || true
