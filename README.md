# KANNEL IN DOCKER
[![Build Status](https://travis-ci.org/ngendah/kannel-docker.svg?branch=master)](https://travis-ci.org/ngendah/kannel-docker)

Can Kannel run in docker and be connected to a usb modem?

# Running on linux

1. Clone the project

2. Copy `env-sample` file to `.env`
    ```
    $ cp env-sample .env
    ```

3. Connect your usb modem

    * Obtain the `tty` the usb modem is connected to by executing the command;
    
    ```
    $ dmesg | grep tty
    ```
    
4. Update your `.env` file `KANNEL_DEVICE_TTY` with the usb modem `tty`.

5. On `main.yml` on `bearerbox.devices` check if the usb modem `tty` is listed and if its not add it.

6. Create directory `conf.d` and copy `bearerbox.conf`, `redis.conf`, `sms-service.conf` and `modem.conf` from `conf.d.sample` to `conf.d`.
    ```
    $ mkdir conf.d && cp conf.d.sample/bearerbox.conf conf.d.sample/modem.conf conf.d.sample/redis.conf conf.d.sample/sms-service.conf conf.d
    ```

9. Update the remaining `.env` file variables.
    
    In the `conf.d.sample` directory I have included my `huawei e3131` modem configuration as a sample.
    
    [Kannel GSM Modem guide](https://www.kannel.org/download/kannel-userguide-snapshot/userguide.html#sms-gateway) provides a guide on how to obtain and set these values.

10. Build and run;
    ```
    $ docker-compose -f main.yaml up --build
    ```
    
11. Examine CLI for any errors, if all ok test sending as follows;
    ```
    $ lynx -dumps http://localhost:8008//cgi-bin/sendsms?username=kannel&password=kannel&to=&text=
    ```
    
#### NOTES:
1. New lines have meaning and should only be used to separate configuration groups.

2. If your USB modem has a windows application or device drivers that are used to connect to it, you could use `wireshark` `usbpcap` to sniff it to obtain its `init-string`.
