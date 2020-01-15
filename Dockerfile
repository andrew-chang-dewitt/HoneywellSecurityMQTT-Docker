# Special attention is required to allow the container to access the 
# USB device that is plugged into the host.

# The container needs priviliged access to /dev/bus/usb on the host.
# 
# docker run -itd \					' *interactive mode & detatch
#   --name rf2mqtt_v2 \					' optional name of container
#   --restart=always \					' optional restart for production runs
#   --privileged \					' *required for proper access to usb dongle
#   -v /dev/bus/usb:/dev/bus/usb \			' *required for any access to usb dongle
#   rf2mqtt_v2						' *base image

# docker run -itd --name rf2mqtt_v2 --restart=always --privileged -v /dev/bus/usb:/dev/bus/usb rf2mqtt_v2

FROM arm64v8/alpine:latest
MAINTAINER Andrew Chang-DeWitt

#
# Define environment variables
# 
# Use this variable when creating a container to specify the MQTT broker host.
# uses default mqtt host & port values for most configurations, but can be 
# specified w/ -e flag on run
ENV MQTT_HOST="127.0.0.1"
ENV MQTT_PORT=1883
ENV LOG_FILE="/app/rf2mqtt.log"

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
# Build and install HoneywellSecurityMQTT
#
RUN git clone https://github.com/fusterjj/HoneywellSecurityMQTT.git /honeywell && \
  cd /honeywell/src && \
  mv mqtt_config.h mqtt_config.h.original && \
  touch mqtt_config.h && \
  echo '#define MQTT_USERNAME ""' >> mqtt_config.h && \
  echo '#define MQTT_PASSWORD ""' >> mqtt_config.h && \
  echo "#define MQTT_HOST \"$MQTT_HOST\"" >> mqtt_config.h && \
  echo "#define MQTT_PORT $MQTT_PORT" >> mqtt_config.h && \
  cat mqtt_config.h && \
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
ENTRYPOINT ["/honeywell/src/honeywell"]
