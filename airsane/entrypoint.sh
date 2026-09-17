#!/bin/sh

# Install drivers
if find /opt/drivers -type f -name '*.deb' 2>/dev/null | grep -q . ; then
	dpkg -i /opt/drivers/*.deb || {
		apt-get update && \
		env DEBIAN_FRONTEND=noninteractive \
		apt-get install -y --fix-broken --no-install-recommends \
		-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
		apt-get clean && rm -rf /var/lib/apt/lists/*
	}
fi

# The image is missing the netbase package, so /etc/protocols and
# /etc/services don't exist. brscan4's network code (getprotobyname())
# gets a NULL protoent back and dereferences it unchecked, segfaulting
# every sane_open() on a network scanner. Install netbase to fix it.
if [ ! -e /etc/protocols ]; then
	apt-get update -qq && \
	env DEBIAN_FRONTEND=noninteractive \
	apt-get install -y -qq --no-install-recommends netbase && \
	apt-get clean && rm -rf /var/lib/apt/lists/*
fi

# Re-register the network scanner(s). The brscan4 (re)install above wipes
# /etc/opt/brother/scanner/brscan4/brsanenetdevice4.cfg on every container
# start, so it has to be re-added here each time rather than once.
if [ -n "$BROTHER_SCANNER_IP" ]; then
	brsaneconfig4 -a name="${BROTHER_SCANNER_NAME:-$BROTHER_SCANNER_MODEL}" \
		model="$BROTHER_SCANNER_MODEL" ip="$BROTHER_SCANNER_IP" || true
fi

# Limit enabled SANE backends to just brother4. With the full stock
# dll.conf (~80 backends), airsaned segfaults during sane_init()/
# sane_get_devices() on startup -- a known issue with AirSane probing
# every enabled backend (see SimulPiscator/AirSane#24). Only brother4
# is needed here, so drop the rest.
printf 'brother4\n' > /etc/sane.d/dll.conf

# Launch UDEV
/lib/systemd/systemd-udevd --daemon

# Start AirSane
exec /usr/local/bin/airsaned "$@"
