#!/usr/bin/env bash
# Toggle a USB device in/out of a libvirt VM.
# Usage: vm-usb-toggle.sh <vm> <vendor_id> [product_id]
#   toggle a single device by vendor (optionally vendor:product)
# Example: vm-usb-toggle.sh windows 046d:c548   # toggles the Logi mouse
set -euo pipefail

# Ensure required tools are found regardless of the calling environment.
export PATH="/run/current-system/sw/bin:$PATH"

VM="${1:?usage: vm-usb-toggle.sh <vm> <vendor[:product]>}"
SPEC="${2:?usage: vm-usb-toggle.sh <vm> <vendor[:product]>}"

VENDOR="${SPEC%%:*}"
PRODUCT=""
if [[ "$SPEC" == *:* ]]; then
  PRODUCT="${SPEC##*:}"
fi

VIRSH=(sudo -n virsh)
if ! "${VIRSH[@]}" list >/dev/null 2>&1; then
  echo "ERROR: cannot talk to libvirt (sudo -n may need a cached credential)." >&2
  exit 1
fi

# Build a temp USB hostdev XML, identifying by vendor[:product] so the
# chosen physical port/bus number doesn't matter.
XML="$(mktemp /tmp/vm-usb.XXXXXX.xml)"
cat > "$XML" <<EOF
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='0x${VENDOR}'/>
EOF
if [[ -n "$PRODUCT" ]]; then
  echo "    <product id='0x${PRODUCT}'/>" >> "$XML"
fi
cat >> "$XML" <<EOF
  </source>
</hostdev>
EOF

# Determine current state: is a matching USB hostdev already attached?
in_vm="$(
  "${VIRSH[@]}" dumpxml "$VM" 2>/dev/null \
    | sed -n '/<hostdev mode=.subsystem. type=.usb. /,/<\/hostdev>/p' \
    | grep -qi "vendor id='0x${VENDOR}'" && echo yes || echo no
)"

if [[ "$in_vm" == "yes" ]]; then
  echo "Detaching ${SPEC} from ${VM}..."
  "${VIRSH[@]}" detach-device "$VM" "$XML"
  echo "Detached."
else
  echo "Attaching ${SPEC} to ${VM}..."
  "${VIRSH[@]}" attach-device "$VM" "$XML"
  echo "Attached."
fi
rm -f "$XML"
