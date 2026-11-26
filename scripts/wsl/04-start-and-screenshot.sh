#!/usr/bin/env bash
# Start a created VM headless, unlock it, and grab a screenshot through
# vphoned (base64 JPEG over vsock) - the reliable way to *see* the guest
# without opening a window.
# Keep this script's session alive while you use the VM: when the WSL
# session that started QEMU closes, the VM is killed with it.
# Usage: 04-start-and-screenshot.sh [VM_NAME] [OUT.jpg]
set -euo pipefail
name=${1:-MyPhone}
out=${2:-$HOME/vphone-home.jpg}
cd ~/vphone-linux
sudo mount -o remount,size=12G /dev/shm 2>/dev/null || true
SMP=8 ./setup/start-vm.sh --no-window "$name"
CID=$(cat ~/vphone-setup-work/devices/"$name"/cid 2>/dev/null || echo 3)
CID=$CID ./tools/vphoned.sh POST /v1/rpc '{"method":"screen.unlock","params":{},"id":1}' || true
sleep 20
CID=$CID ./tools/vphoned.sh POST /v1/rpc '{"method":"screen.screenshot","params":{},"id":1}' > /tmp/vphone-shot.json
python3 - "$out" << 'PY'
import json, base64, sys
d = json.load(open('/tmp/vphone-shot.json'))
r = d.get('result') or {}
b64 = r.get('image') or r.get('data') or r.get('jpeg') or (r if isinstance(r, str) else '')
raw = base64.b64decode(b64)
open(sys.argv[1], 'wb').write(raw)
print("saved", sys.argv[1], len(raw), "bytes")
PY
echo "VM is running. Stop it with: ./setup/start-vm.sh --stop $name"
