#!/bin/bash
echo "Starting Crowdsec Openresty Bouncer install"
NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/"
CONFIG_PATH="/etc/crowdsec/bouncers/"
DATA_PATH="/var/lib/crowdsec/lua/"
SSL_CERTS_PATH="/etc/ssl/certs/ca-certificates.crt"
LAPI_DEFAULT_PORT="8080"

#Accept cmdline arguments to overwrite options.
while [[ $# -gt 0 ]]
do
    case $1 in
        --NGINX_CONF_DIR=*)
            NGINX_CONF_DIR="${1#*=}"
        ;;
        --LIB_PATH=*)
            LIB_PATH="${1#*=}"
        ;;
        --CONFIG_PATH=*)
            CONFIG_PATH="${1#*=}"
        ;;
        --DATA_PATH=*)
            DATA_PATH="${1#*=}"
        ;;
        --SSL_CERTS_PATH=*)
            SSL_CERTS_PATH="${1#*=}"
        ;;
        -y|--yes)
            # no-op, kept for backward compatibility
        ;;
        --docker)
            DOCKER="1"
        ;;
    esac
    shift
done

check_pkg_manager(){
    if [ -f /etc/redhat-release ]; then
        SSL_CERTS_PATH="/etc/ssl/certs/ca-bundle.crt"
    elif [ -f /etc/system-release ]; then
        if grep -q "Amazon Linux release 2 (Karoo)" < /etc/system-release ; then
            SSL_CERTS_PATH="/etc/ssl/certs/ca-bundle.crt"
        fi
    elif ! [ -f /etc/debian_version ]; then
        echo "Distribution is not supported, exiting."
        exit
    fi   
}

requirement() {
    mkdir -p "${CONFIG_PATH}"
    mkdir -p "${DATA_PATH}"
    mkdir -p "${NGINX_CONF_DIR}"
    mkdir -p "${LIB_PATH}"
}

gen_config_file() {
    #Don't overwrite the existing file
    if [ ! -f "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf" ]; then
        #check if cscli is available, this can be installed on systems without crowdsec installed
        if command -v cscli >/dev/null; then
            SUFFIX=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)
            API_KEY=$(cscli bouncers add "crowdsec-openresty-bouncer-${SUFFIX}" -o raw)
            PORT=$(cscli config show --key "Config.API.Server.ListenURI"|cut -d ":" -f2)
            if [ ! -z "$PORT" ]; then
                LAPI_DEFAULT_PORT=${PORT}
            fi
            CROWDSEC_LAPI_URL="http://127.0.0.1:${LAPI_DEFAULT_PORT}"
        fi
        API_KEY=${API_KEY} CROWDSEC_LAPI_URL="${CROWDSEC_LAPI_URL}" envsubst '$API_KEY $CROWDSEC_LAPI_URL' < ./config/config_example.conf > "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
        [ -n "${API_KEY}" ] && echo "New API key generated to be used in '${CONFIG_PATH}/crowdsec-openresty-bouncer.conf'"
    else
        #Patch the existing file with new parameters if the need to be added
        echo "Patch crowdsec-openresty-bouncer.conf .." 
        sed "s/=.*//g" "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf" > /tmp/crowdsec.conf.raw
        sed "s/=.*//g" ./config/config_example.conf  > /tmp/config_example.conf.raw
        if grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw ; then
            grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw > /tmp/config_example.newvals
            cp "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf" "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf.bak"
            #Make sure we start on a new line.
            echo "" >>"${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
            grep -f /tmp/config_example.newvals /tmp/crowdsec/config/config_example.conf >> "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
        fi
    fi
    sed -i 's|/var/lib/crowdsec/lua|'"${DATA_PATH}"'|' "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
}

install() {
    mkdir -p "${DATA_PATH}/templates/"
    cp -r lua/lib/* "${LIB_PATH}/"
    cp templates/* "${DATA_PATH}/templates/"
    #Patch the nginx config file
    SSL_CERTS_PATH=${SSL_CERTS_PATH} envsubst '$SSL_CERTS_PATH' < openresty/${NGINX_CONF} > "${NGINX_CONF_DIR}/${NGINX_CONF}"
    sed -i 's|/etc/crowdsec/bouncers|'"${CONFIG_PATH}"'|' "${NGINX_CONF_DIR}/${NGINX_CONF}"
}


if ! [ "$(id -u)" = 0 ] && [ -z ${DOCKER} ]; then
    echo "Please run the install script as root or with sudo"
    exit 1
fi

[ -z ${DOCKER} ] && check_pkg_manager
requirement
gen_config_file
install
echo "crowdsec-openresty-bouncer installed successfully"
echo ""
[ -z ${DOCKER} ] && echo "Add 'include /usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf;' in your nginx configuration file to enable the bouncer."
echo ""
[ -z ${DOCKER} ] && echo "Run 'sudo systemctl restart openresty.service' to start openresty-bouncer"
exit 0