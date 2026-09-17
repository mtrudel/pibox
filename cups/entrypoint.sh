#!/bin/sh
set -e

# /config is a named volume, so a fresh volume (new host, 'docker compose
# down -v', etc.) starts without our customizations. Ensure they're present
# before the image's own run_cups.sh takes over (it copies /config/cupsd.conf
# over /etc/cups/cupsd.conf on every start).
mkdir -p /config
touch /config/cupsd.conf

# Drop the '_cups' DNS-SD subtype so macOS treats the shared queue as a plain
# IPP-Everywhere printer instead of forcing its bundled Generic PostScript
# driver, which gates duplex behind an installable option that defaults off
# regardless of what the printer actually supports.
# https://github.com/NorthIsUp/brother-printbot/pull/4
if ! grep -q '^BrowseDNSSDSubTypes' /config/cupsd.conf; then
	echo 'BrowseDNSSDSubTypes _print,_universal' >> /config/cupsd.conf
fi

exec /root/run_cups.sh
