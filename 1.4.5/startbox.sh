#!/usr/bin/env sh

# debug mode
# set -x

kannel_dir="$KANNEL_DIR"
config="$KANNEL_DIR/$BASE_CONFIG_FILENAME"
included_configs=$INCLUDE_CONFIGS
box="$BOX_TYPE"

[[ ! -z "$included_configs" ]] || exit 1

make_config_file(){
    [[ ! -f $config ]] || rm $config
    for conf in $included_configs; do
        local config_file_path=$kannel_dir/conf.d/$conf
        configure "$config_file_path"
        echo "include=$config_file_path" >> $config
        echo "" >> $config
    done
}

configure(){
    if [[ z "$KANNEL_BEARERBOX_HOST" ]]; then
        echo "kannel bearerbox host has not been set"
        exit 1
    fi
    if [[ -z "$KANNEL_MSISDN" ]]; then
        echo "kannel msisdn number has not been set"
        exit 1
    fi
    # Regular expressions :( ?
    # checkout "Mastering Regular Expressions by Jeffrey E. F. Friedl, O'Reilly"
    configure_bearer $1
    configure_database $1
    configure_modem $1
}

configure_bearer(){
    sed -i "s|^\(forced-smsc\\s*\)=.*$|\\1= $KANNEL_SMSC|g" $1
    sed -i "s|^\(default-smsc\\s*\)=.*$|\\1= $KANNEL_SMSC|g" $1
    sed -i "s|^\(accepted-smsc\\s*\)=.*$|\\1= $KANNEL_SMSC|g" $1
    sed -i "s|^\(bearerbox-host\\s*\)=.*$|\\1= $KANNEL_BEARERBOX_HOST|g" $1
    sed -i "s|^\(global-sender\\s*\)=.*$|\\1= $KANNEL_MSISDN|g" $1
    sed -i "s|^\(allowed-receiver-prefix\\s*\)=.*$|\\1= $KANNEL_MSISDN|g" $1
}

configure_modem(){
    local modem_present=`grep -rni 'modemtype' $1 | wc -l`
    [[ $modem_present -ne 0 ]] || return
    sed -i "s|^\(my-number\\s*\)=.*$|\\1= $KANNEL_MSISDN|g" $1
    sed -i "s|^\(device\\s*\)=.*$|\\1= $KANNEL_DEVICE_PUTTY|g" $1
    sed -i "s|^\(host\\s*\)=.*$|\\1= $KANNEL_DEVICE_HOST|g" $1
}

configure_database(){
    sed -i "s|^\(dlr-storage\\s*\)=.*$|\\1= ${KANNEL_DLR_STORAGE_TYPE:-internal}|g" $1
    [[ "$KANNEL_DLR_STORAGE" != "internal" ]] || return
    local is_redis=`grep -rni 'redis-connection' $1 | wc -l`
    [[ $is_redis -eq 0 ]] || configure_redis $1 && return
    local is_pgsql=`grep -rni 'pgsql-connection' $1 | wc -l`
    [[ $is_pgsql -eq 0 ]] || configure_pgsql $1 && return
    local is_mysql=`grep -rni 'mysql-connection' $1 | wc -l`
    [[ $is_mysql -eq 0 ]] || configure_mysql $1 && return
}

configure_pgsql(){
    sed -i "s|^\(host\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_HOST|g" $1
    sed -i "s|^\(username\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_USERNAME|g" $1
    sed -i "s|^\(database\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_DBNAME|g" $1
    sed -i "s|^\(password\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_PASSWORD|g" $1
}

configure_mysql(){
    sed -i "s|^\(host\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_HOST|g" $1
    sed -i "s|^\(username\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_USERNAME|g" $1
    sed -i "s|^\(database\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_DBNAME|g" $1
    sed -i "s|^\(password\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_PASSWORD|g" $1
}

configure_redis(){
    sed -i "s|^\(host\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_HOST|g" $1
    sed -i "s|^\(port\\s*\)=.*$|\\1= ${KANNEL_DLR_STORAGE_PORT:-6379}|g" $1
    sed -i "s|^\(database\\s*\)=.*$|\\1= ${KANNEL_DLR_STORAGE_DBNAME:-1}|g" $1
    if [[ ! -z"$KANNEL_DLR_STORAGE_PASSWORD" ]]; then
        sed -i "s|^#?\(password\\s*\)=.*$|\\1= $KANNEL_DLR_STORAGE_PASSWORD|g" $1
    fi
}

if [[ $box == "bearerbox" ]]; then
    make_config_file
    exec bearerbox -v 0 $config
elif [[ $box == "smsbox" ]]; then
    make_config_file
    exec smsbox -v 0 $config
else
    echo "BOX_TYPE=$box not cannot be started, review startbox.sh to enable it"
fi
