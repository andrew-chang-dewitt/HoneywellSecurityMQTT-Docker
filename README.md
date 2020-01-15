# HoneywellSecurityMQTT-Docker

An Alpine based Docker build of [fusterjj/HoneywellSecurityMQTT](https://github.com/fusterjj/HoneywellSecurityMQTT).

## Usage

This image defaults to MQTT Host location of 127.0.0.1 & port of 1883 with no user or password 
for MQTT either. If these defaults are acceptable for your use case, all you need to do is pull 
the docker image, 

```
$ docker pull andrewchangdewitt/honeywell-security-mqtt
```

then run it with privilaged access & mapping the host usb & network to the image.

```
$ docker run -itd \
  --network host \
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  honeywell-security-mqtt:latest
```

Additionaly, it is recommended & set the `--restart` flag to make it easier to manage your security 
setup & I also like to name the container to make it easier to manage later by adding the `--name` flag.

If everything is running correctly, you should see something similar to the following when you check 
the container's logs: 

```
$ docker logs honeywell-security-mqtt
>> Mqtt - set LWT message to: FAILED
>> Mqtt - connected
Found Rafael Micro R820T tuner
Successfully set the frequency to 345000000
Successfully set gain to 350
Exact sample rate is: 1000000.026491 Hz
Successfully set the sample rate to 1000000
>> Mqtt - Message (1) published
```

## Customizing configurations

If you have a different MQTT Host or Port, or use user & password settings on your MQTT server, 
you will need to customize the setup & build the docker image yourself. To do this, first clone this 
repo to a location of your choosing.

```
$ git clone git@github.com:andrew-chang-dewitt/HoneywellSecurityMQTT-Docker.git ~/honeywell-security-mqtt
```

Then, edit the file named `mqtt_config.h` with your configuration. For example, if your MQTT Host isn't 
127.0.0.1, you would change line 3 from 

```
#define MQTT_HOST "127.0.0.1"
```

to 

```
#define MQTT_HOST "x.x.x.x"
```

where `x.x.x.x` is your MQTT Host address. Changing the username, password, or host port is the same. When 
done, use Docker's `build` to compile the image. 

```
$ docker build ~/honeywell-security-mqtt -t honeywell-security-mqtt:customized
```

Then run this image, just like you would if you had pulled the default configuration from DockerHub:

```
$ docker run -itd \
  --name honeywell-security-mqtt \
  --restart=always \
  --network host \
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  honeywell-security-mqtt:customized 
```
