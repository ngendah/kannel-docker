# KANNEL IN DOCKER

Can Kannel run in docker and be connected to a usb modem?

# Running (linux)

1. Clone the project

2. Copy `env-sample` file to `.env` and update its variables, with the exception of `KANNEL_DEVICE_PUTTY`
    ```
    $ mv env-sample .env
    ```

3. Connect your usb modem

    * Obtain the `tty` your usb modem is connected to by executing the command;
    
    ```
    $ dmesg | grep tty
    ```
    
4. Update your `.env` file `KANNEL_DEVICE_PUTTY` with the usb modem `tty`.

5. On `main.yml` on `bearerbox.devices` check if the usb modem `tty` is listed and if its not add it.

6. On the `conf.d` add your modems configuration by copying, renaming and updating it.
    
    In the `conf.d` directory I have included my modem, `huawei-e3131`,  configuration as a sample.
    
    [Kannel GSM Modem guide](https://www.kannel.org/download/kannel-userguide-snapshot/userguide.html#sms-gateway) provides an excellent guide on how to obtain and set this values.

7. On `main.yaml` file `bearerbox.environments:INCLUDE_CONFIGS` add your modem configuration and remove the listed `huawei-e3131.conf`

8. Build and run;
   
   ```
   $ docker-compose -f main.yaml up --build
    ```
    
9. Examine CLI for any errors, if all ok test sending as follows;
    ```
    $ curl -X GET http://localhost:8008//cgi-bin/sendsms?username=kannel&password=kannel&to=&text=
    ```
    
### NOTE:
New lines have meaning and should only be used to separate configuration groups.