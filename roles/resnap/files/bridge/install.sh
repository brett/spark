#!/bin/bash
# Install resnap + the bridge (schedule, alerts, freshness check) on obsidian
# WITHOUT running spark. Run as brett (not root): it uses sudo for each
# privileged step, and reads the restic password from `pass` as brett so the
# password never touches disk or a command line.
#
# Idempotent: safe to re-run. Installs no drives: add each drive's line to
# /usr/local/etc/resnap/drives and enable its timer when it is converted to
# plain ext4 (Phase 1 / 3 of the migration plan):
#   echo "darkstar <fs-uuid>" | sudo tee -a /usr/local/etc/resnap/drives
#   sudo systemctl enable --now resnap@darkstar.timer
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
resnap_src="$here/../resnap"
conf=/usr/local/etc/resnap

if [ "$(id -u)" -eq 0 ]; then
    echo "run as brett, not root (the password comes from your pass store)" >&2
    exit 1
fi

echo "== packages: restic, libnotify, curl"
sudo pacman -S --needed --noconfirm restic libnotify curl

echo "== resnap scripts (Peter's Makefile; keeps any existing config files)"
(cd "$resnap_src" && sudo make install)

echo "== restic password (from pass backups/resnap)"
if sudo test -s "$conf/password"; then
    echo "   already present; left unchanged"
else
    pass show backups/resnap | head -n1 | sudo tee "$conf/password" > /dev/null
    sudo chmod 600 "$conf/password"
    sudo test -s "$conf/password" || { echo "password file is empty" >&2; exit 1; }
    echo "   written (0600 root)"
fi

echo "== excludes (bridge version: + /nix/store, caches, annex objects)"
sudo install -m 644 "$here/excludes" "$conf/excludes"

echo "== bridge scripts"
for s in resnap-present resnap-alert resnap-stale; do
    sudo install -m 755 "$here/$s" "/usr/local/bin/$s"
done
sudo install -D -m 644 "$here/README.md" /usr/local/share/doc/resnap/README.md

echo "== systemd units"
sudo install -m 644 "$here"/systemd/* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now resnap-stale.timer

echo
echo "Installed. Drives configured:"
grep -vE '^\s*(#|$)' "$conf/drives" || echo "   (none yet; add one per converted drive, see the header of this script)"
