# This is a super straightforward dockerization of the PiDP project as
# presented at https://obsolescence.wixsite.com/obsolescence/pidp-11. No
# attempt is made to clean things up or otherwise improve on matters beyond:
#
# 1. Getting the project to build on 64 bit ARM
# 2. Hacking out LED brightness support to cut down on system load
# 3. No systems are installed

# rpc libs seem to preclude using Alpine here, though this would be easily resolved with a rebuilt & sensible
# build structure in the downloaded project
FROM debian

RUN apt-get update && apt-get install -y bsdmainutils build-essential curl file libpcap-dev libreadline-dev libsdl2-dev rpcbind sudo

RUN mkdir /opt/pidp11

RUN curl -SL https://www3.ispnet.net/pidp11/pidp11.tar.gz | tar -xvzC /opt/pidp11

# Clean up stuff in simh fork (client) and rebuild it. Use sed instead of patches to keep this dockerfile self-contained
RUN rm /opt/pidp11/src/02.3_simh/4.x+realcons/bin-rpi/pdp11_realcons
RUN sed -i 's/LIBPCAP=.*/LIBPCAP=-lpcap/' /opt/pidp11/src/02.3_simh/4.x+realcons/src/quickmake
RUN sed -i 's/.*console_controller_event_func_t.*realcons_event_cpu_reset.*//' /opt/pidp11/src/02.3_simh/4.x+realcons/src/scp.c
RUN (cd /opt/pidp11/src && . ./makeclient.sh)

# Remove prebuilt scansw binary and rebuild it on native platform
RUN rm /opt/pidp11/src/11_pidp_server/scanswitch/scansw
RUN (cd /opt/pidp11/src/11_pidp_server/scanswitch && make)

# Clean up stuff in blinkenlightd (server) and rebuild it. Use sed to keep this dockerfile self-contained
# Don't be so strict about build type, so as to enable arm64
RUN sed -i 's/arm-linux-gnueabihf-gcc/gcc/' /opt/pidp11/src/07.1_blinkenlight_server/makefile
RUN sed -i 's/arm-linux-gnueabihf-gcc/gcc/' /opt/pidp11/src/11_pidp_server/pidp11/makefile
# Hack out dimming support for a ~15x decrease in CPU load. We do this by not
# bothering to run LED brightness through phases in gpio.c. This is a SUPER
# bogus hack that would be better accomplished by tearing it all out and
# starting from scratch, but who has time for that.
#
# 1. Replace the delay interval on line 61 from 50000 to 31 * 50000 (1550000)
RUN sed -i 's/50000/1550000/' /opt/pidp11/src/11_pidp_server/pidp11/gpio.c
# 2. Loop exactly once on line 268, not 'GPIOPATTERN_LED_BRIGHTNESS_PHASES' number of times
RUN sed -i 's/GPIOPATTERN_LED_BRIGHTNESS_PHASES/1/' /opt/pidp11/src/11_pidp_server/pidp11/gpio.c
RUN (cd /opt/pidp11/src && . ./makeserver.sh)

# Uncomment if you wish to populate your dockerfile with a set of OSs
#RUN curl -SL https://www3.ispnet.net/pidp11/systems.tar.gz | tar -xvzC /opt/pidp11

CMD (cd /opt/pidp11/bin && . ./pidp11.sh)
