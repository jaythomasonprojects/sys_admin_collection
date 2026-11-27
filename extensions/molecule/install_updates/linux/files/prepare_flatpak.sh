#!/bin/bash
set -euo pipefail
export LC_ALL=C

flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system --noninteractive --assumeyes \
    flathub org.gnome.Calculator >/dev/null
candidate=$(flatpak info --system --show-commit org.gnome.Calculator)
history=$(flatpak remote-info --system --log flathub org.gnome.Calculator)
older=$(awk '$1 == "Commit:" && !seen[$2]++ {print $2}' \
    <<<"$history" | awk 'NR == 2')
if [[ ! "$older" =~ ^[a-f0-9]{64}$ || "$older" == "$candidate" ]]; then
    echo 'No real older Flatpak commit is available; acceptance is incomplete.' >&2
    exit 1
fi
flatpak update --system --noninteractive --assumeyes --commit="$older" \
    org.gnome.Calculator >/dev/null
installed=$(flatpak info --system --show-commit org.gnome.Calculator)
if [[ "$installed" != "$older" ]]; then
    echo 'The real older Flatpak fixture was not deployed.' >&2
    exit 1
fi
runtime=$(flatpak info --system --show-runtime org.gnome.Calculator)
printf '{"before":"%s","candidate":"%s","runtime":"%s"}\n' \
    "$installed" "$candidate" "$runtime"
