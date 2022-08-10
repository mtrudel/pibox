# PiDP-11 in Docker

With customizations to build for local platform (32 and 64 bit raspberry pi OS supported). 

To run: 

```
docker build . -t pidp11
docker run --restart unless-stopped --privileged pidp11
```
