#!/usr/bin/env sh

# debug mode
# set -x

kannel_dir="$KANNEL_DIR"
config="$KANNEL_DIR/$BASE_CONFIG_FILENAME"
included_configs=$INCLUDE_CONFIGS
log_level=${KANNEL_LOG_LEVEL:-0}

box="$BOX_TYPE"
bearerbox_host=$KANNEL_BEARERBOX_HOST
smsc=$KANNEL_BEARERBOX_SMSC
msisdn=$KANNEL_BEARERBOX_MSISDN
callback_url=$KANNEL_SMSS_CALLBACK_URL

dlr_storage_type=$KANNEL_DLR_STORAGE_TYPE
dlr_storage=$KANNEL_DLR_STORAGE
dlr_storage_host=$KANNEL_DLR_STORAGE_HOST
dlr_storage_username=$KANNEL_DLR_STORAGE_USERNAME
dlr_storage_dbname=$KANNEL_DLR_STORAGE_DBNAME
dlr_storage_password=$KANNEL_DLR_STORAGE_PASSWORD
dlr_storage_port=$KANNEL_DLR_STORAGE_PORT

device_tty=$KANNEL_DEVICE_TTY
device_host=$KANNEL_DEVICE_HOST
device_type=$KANNEL_DEVICE_TYPE
modem_smscid=$KANNEL_DEVICE_SMSCID
modem_name=$KANNEL_DEVICE_MODEM_NAME
modem_manufacturer=$KANNEL_DEVICE_MANUFACTURER
modem_detect_string=$KANNEL_DEVICE_MODEM_DETECT_STRING
modem_init_string=$KANNEL_DEVICE_MODEM_INIT_STRING


[[ ! -z "$included_configs" ]] || exit 1

make_config_file(){
    [[ ! -f "$config" ]] || rm $config
    for conf in $included_configs; do
        local config_file_path=$kannel_dir/conf.d/$conf
        configure "$config_file_path"
        echo "include=$config_file_path" >> $config
        echo "" >> $config
    done
}

configure(){
    if [[ -z "$bearerbox_host" ]]; then
        echo "kannel bearerbox host has not been set"
        exit 1
    fi
    if [[ -z "$msisdn" ]]; then
        echo "kannel msisdn number has not been set"
        exit 1
    fi
    # Regular expressions :( ?
    # checkout "Mastering Regular Expressions by Jeffrey E. F. Friedl, O'Reilly"
    configure_bearer $1
    configure_database $1
    configure_modem $1
    configure_service $1
}

configure_bearer(){
    sed -i "s|^\(forced-smsc\\s*\)=.*$|\\1= $smsc|g" $1
    sed -i "s|^\(default-smsc\\s*\)=.*$|\\1= $smsc|g" $1
    sed -i "s|^\(accepted-smsc\\s*\)=.*$|\\1= $smsc|g" $1
    sed -i "s|^\(bearerbox-host\\s*\)=.*$|\\1= $bearerbox_host|g" $1
    sed -i "s|^\(global-sender\\s*\)=.*$|\\1= $msisdn|g" $1
    sed -i "s|^\(allowed-receiver-prefix\\s*\)=.*$|\\1= $msisdn|g" $1
}

configure_modem(){
    local smsc_present=`grep -rni 'group *= *smsc' $1 | wc -l`
    [[ $smsc_present -ne 0 ]] || return
    sed -i "s|^\(my-number\\s*\)=.*$|\\1= $msisdn|g" $1
    sed -i "s|^\(device\\s*\)=.*$|\\1= $device_tty|g" $1
    sed -i "s|^\(host\\s*\)=.*$|\\1= $device_host|g" $1
    sed -i "s|^\(smsc-id\\s*\)=.*$|\\1= $modem_smscid|g" $1
    local modem_present=`grep -rni 'group *= *modems' $1 | wc -l`
    [[ $modem_present -ne 0 ]] || return
    sed -i "s|^\(modemtype\\s*\)=.*$|\\1= $modem_manufacturer|g" $1
    sed -i "s|^\(id\\s*\)=.*$|\\1= $modem_name|g" $1
    sed -i "s|^\(name\\s*\)=.*$|\\1= $modem_name|g" $1
    sed -i "s|^\(detect-string\\s*\)=.*$|\\1= $modem_detect_string|g" $1
    sed -i "s|^\(init-string\\s*\)=.*$|\\1= $modem_init_string|g" $1
}

configure_service(){
    local service_present=`grep -rni 'group *= *sms-service' $1 | wc -l`
    [[ $service_present -ne 0 ]] || return
    sed -i "s|^\(post-url\\s*\)=.*$|\\1= $callback_url|g" $1
}
configure_database(){
    sed -i "s|^\(dlr-storage\\s*\)=.*$|\\1= ${dlr_storage_type:-internal}|g" $1
    [[ "$dlr_storage" != "internal" ]] || return
    local is_redis=`grep -rni 'redis-connection' $1 | wc -l`
    [[ $is_redis -eq 0 ]] || configure_redis $1 && return
    local is_pgsql=`grep -rni 'pgsql-connection' $1 | wc -l`
    [[ $is_pgsql -eq 0 ]] || configure_pgsql $1 && return
}

configure_pgsql(){
    sed -i "s|^\(host\\s*\)=.*$|\\1= $dlr_storage_host|g" $1
    sed -i "s|^\(username\\s*\)=.*$|\\1= $dlr_storage_username|g" $1
    sed -i "s|^\(database\\s*\)=.*$|\\1= $dlr_storage_dbname|g" $1
    sed -i "s|^\(password\\s*\)=.*$|\\1= $dlr_storage_password|g" $1
}

configure_redis(){
    sed -i "s|^\(host\\s*\)=.*$|\\1= $dlr_storage_host|g" $1
    sed -i "s|^\(port\\s*\)=.*$|\\1= ${dlr_storage_port:-6379}|g" $1
    sed -i "s|^\(database\\s*\)=.*$|\\1= ${dlr_storage_dbname:-1}|g" $1
    if [[ ! -z"$dlr_storage_password" ]]; then
        sed -i "s|^#?\(password\\s*\)=.*$|\\1= $dlr_storage_password|g" $1
    fi
}

if [[ $box == "bearerbox" ]]; then
    make_config_file
    exec bearerbox -v $log_level $config
elif [[ $box == "smsbox" ]]; then
    make_config_file
    exec smsbox -v $log_level $config
else
    echo "BOX_TYPE=$box not cannot be started, review startbox.sh to enable it"
fi
