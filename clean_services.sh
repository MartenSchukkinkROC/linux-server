#!/bin/bash

# Lijst van services om uit te schakelen en te stoppen
SERVICES=(
  accounts-daemon
  avahi-daemon
  bluetooth
  cups
  ModemManager
  spice-vdagentd
  switcheroo-control
  udisks2
  upower
  rtkit-daemon
  iscsi-onboot
  iscsi-starter
  multipathd
  nvmefc-boot-connections
  qemu-guest-agent
  sssd
)

SERVICES_KEEP=(
  gdm
  vmtoolsd
  vgauthd
  kdump
  libstoragemgmt
  smartd
  tuned
)

echo "🔧 Uitschakelen van services, sockets en paths..."

for unit in "${SERVICES[@]}"; do
  for suffix in service socket path; do
    UNIT_NAME="${unit}.${suffix}"
    if systemctl list-unit-files | grep -q "^$UNIT_NAME"; then
      echo "➡️  Disabling $UNIT_NAME"
      systemctl disable --now "$UNIT_NAME"
    fi
  done
done

echo "✅ Klaar. Alle opgegeven services, sockets en paths zijn uitgeschakeld."