# Special attention is required to allow the container to access the 
# USB device that is plugged into the host.

# The container needs priviliged access to /dev/bus/usb on the host.
# 
# docker run -itd \					' *interactive mode & detatch
#   --name honeywell-security-mqtt \			' optional name of container
#   --restart=always \					' optional restart for production runs
#   --network host					' *required for proper network access
#   --privileged \					' *required for proper access to usb dongle
#   -v /dev/bus/usb:/dev/bus/usb \			' *required for any access to usb dongle
#   honeywell-security-mqtt				' *base image

# docker run -itd --name honeywell-security-mqtt --restart=always --privileged -v /dev/bus/usb:/dev/bus/usb honeywell-security-mqtt

FROM arm64v8/alpine:latest
MAINTAINER Andrew Chang-DeWitt

#
# First install build dependencies 
#
RUN apk add --no-cache --virtual build-deps alpine-sdk cmake git libusb-dev 

#
# Build & install rtl-sdr
#
RUN mkdir /tmp/src && \
  cd /tmp/src && \
  git clone git://git.osmocom.org/rtl-sdr.git && \
  mkdir /tmp/src/rtl-sdr/build && \
  cd /tmp/src/rtl-sdr/build && \
  cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNAL_DRIVER=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr/local && \
  make && \
  make install && \
  chmod +s /usr/local/bin/rtl_* 

#
# Add build-dep for HSMQTT (it might be an operating dep too?
# 
RUN apk add --no-cache mosquitto-dev

#
# Clone & modify fusterjj/HoneywellSecurityMQTT
#
RUN git clone https://github.com/fusterjj/HoneywellSecurityMQTT.git /app && \
  cd /app/src && \
  mv mqtt_config.h mqtt_config.h.original
#
# Copy user-modifiable mqtt configuration file in place of the
# original from GitHub
#
COPY mqtt_config.h /app/src/mqtt_config.h

# 
# Build and install HoneywellSecurityMQTT
#
Run cd /app/src && \
  ./build.sh

#
# Clean up /tmp & build deps
#
RUN apk del build-deps && \
  rm -r /tmp/src

# 
# Install additional packages for usb, mqtt, & jq
# 
RUN apk add --no-cache libusb 

#
# Add blacklist for dvb_usb_rtl28xxu module to help prevent kernal errors
#
COPY no-rtl.conf /etc/modprobe.d/no-rtl.conf

#
# When running a container this script will be executed
#
ENTRYPOINT ["/app/src/honeywell"]
