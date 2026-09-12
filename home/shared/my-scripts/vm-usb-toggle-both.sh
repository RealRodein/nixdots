#!/usr/bin/env bash
# Toggle BOTH passthrough USB devices (keyboard + mouse) into/out of the
# Windows VM together. Triggered by the case power button (via acpid).
#
#   - If a device is currently attached to the VM -> detach both -> host takes
#     back keyboard + mouse.
#   - If neither is attached -> attach both -> VM takes keyboard + mouse.
#
# Safe as a no-op when the VM is off (virsh calls fail and are ignored).
set -u

# acpid runs commands with no PATH set, so make sure the tools this script
# needs (sed/grep/id/logger/virsh) are found regardless of the caller.
export PATH="/run/current-system/sw/bin:$PATH"

# A single physical power-button press can emit more than one ACPI event,
# which would fire this script twice in a row and toggle back and forth.
# Debounce: if we already ran within the last few seconds, ignore this call.
DEBOUNCE_STAMP=/dev/shm/vm-usb-toggle.stamp
DEBOUNCE_SECS=3
if [ -z "${VM_USB_IGNORE_DEBOUNCE:-}" ] \
   && [ -f "$DEBOUNCE_STAMP" ] \
   && [ "$(date +%s)" -lt "$(($(cat "$DEBOUNCE_STAMP" 2>/dev/null) + DEBOUNCE_SECS))" ]; then
  logger -t vm-power-btn "power btn debounced (double event)"
  exit 0
fi
echo "$(date +%s)" > "$DEBOUNCE_STAMP"

VIRSH=${VIRSH:-/run/current-system/sw/bin/virsh}
VM="${VM:-windows}"

KEY_XML=/etc/vm-usb-keyboard.xml
MOUSE_XML=/etc/vm-usb-mouse.xml

# When running as a normal user, escalate via the passwordless virsh rule.
if [ "$(id -u)" -ne 0 ]; then
  VIRSH="sudo -n $VIRSH"
fi

# Determine current state: is the keyboard hostdev already attached to the VM?
attached="$(
  $VIRSH dumpxml "$VM" 2>/dev/null \
    | sed -n '/<hostdev mode=.subsystem. type=.usb. /,/<\/hostdev>/p' \
    | grep -qi "vendor id='0x0518'" && echo yes || echo no
)"

if [ "$attached" = "yes" ]; then
  $VIRSH detach-device "$VM" "$KEY_XML"  >/dev/null 2>&1 || true
  $VIRSH detach-device "$VM" "$MOUSE_XML" >/dev/null 2>&1 || true
  logger -t vm-power-btn "VM input -> host"
else
  $VIRSH attach-device "$VM" "$KEY_XML"  >/dev/null 2>&1 || true
  $VIRSH attach-device "$VM" "$MOUSE_XML" >/dev/null 2>&1 || true
  logger -t vm-power-btn "VM input -> guest"
fi
