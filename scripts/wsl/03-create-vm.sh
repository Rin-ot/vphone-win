#!/usr/bin/env bash
# Create the VM with the resource settings a 16 GB host actually needs.
# - /dev/shm must hold the 8 GB guest RAM; WSL gives it only half of WSL's
#   memory by default, so remount it bigger first.
# - WINDOW=0: headless. The GTK window helper can fail to initialize and
#   takes QEMU down with it; verify visually via screenshot instead
#   (04-start-and-screenshot.sh).
# - SMP=8: the first boot's data migration is watchdog-timed by iOS. With
#   SMP=6 and 12 GB for WSL it panicked three times on the test machine;
#   SMP=8 + 14 GB finished in ~14 minutes.
# Usage: 03-create-vm.sh [VM_NAME] [DEVICE] [IOS]
set -euo pipefail
name=${1:-MyPhone}
device=${2:-iPhone17,3}
ios=${3:-26.6.2}
cd ~/vphone-linux
sudo mount -o remount,size=12G /dev/shm
SMP=8 WINDOW=0 ./setup/create-vm.sh --device "$device" --ios "$ios" --scale 1 -y
echo "VM '$name' directory: ~/vphone-setup-work/devices/ (name chosen by create-vm)"
