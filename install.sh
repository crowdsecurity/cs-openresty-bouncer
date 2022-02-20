#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/"
CONFIG_PATH="/etc/crowdsec/bouncers/"
DATA_PATH="/var/lib/crowdsec/lua/"
PKG="apt"
PACKAGE_LIST="dpkg -l"
SSL_CERTS_PATH="/etc/ssl/certs/ca-certificates.crt"

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
        --docker)
		    DOCKER=1
	    ;;
    esac
    shift
done

check_pkg_manager(){
    if [ -f /etc/redhat-release ]; then
        PKG="yum"
        PACKAGE_LIST="yum list installed"
        SSL_CERTS_PATH="/etc/ssl/certs/ca-bundle.crt"
    elif cat /etc/system-release | grep -q "Amazon Linux release 2 (Karoo)"; then
        PKG="yum"
        PACKAGE_LIST="yum list installed"
        SSL_CERTS_PATH="/etc/ssl/certs/ca-bundle.crt"
    elif [ -f /etc/debian_version ]; then
        PKG="apt"
        PACKAGE_LIST="dpkg -l"
    else
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
    if [ -z ${DOCKER} ]; then
        SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
        API_KEY=`cscli bouncers add crowdsec-openresty-bouncer-${SUFFIX} -o raw`
        echo "New API key generated to be used in '${CONFIG_PATH}/crowdsec-openresty-bouncer.conf'"
    else
        API_KEY="1234567890abcdef"
    fi
    API_KEY=${API_KEY} CROWDSEC_LAPI_URL="http://127.0.0.1:8080" envsubst < ./config/config_example.conf > "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
    # Not sure why couldn't patch the path useing envsubst
    sed -i 's|/var/lib/crowdsec/lua|'${DATA_PATH}'|' "${CONFIG_PATH}/crowdsec-openresty-bouncer.conf"
}

check_openresty_dependency() {
    DEPENDENCY=(
        "openresty-opm"
    )
    for dep in ${DEPENDENCY[@]};
    do
        $PACKAGE_LIST | grep ${dep} > /dev/null
        if [[ $? != 0 ]]; then
            echo "${dep} not found, do you want to install it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                "$PKG" install -y -qq ${dep} > /dev/null && echo "${dep} successfully installed"
            else
                echo "unable to continue without ${dep}. Exiting" && exit 1
            fi      
        fi
    done
}

check_lua_dependency() {
    DEPENDENCY=(
        "pintsized/lua-resty-http"
    )
    for dep in ${DEPENDENCY[@]};
    do
        opm list | grep ${dep} > /dev/null
        if [[ $? != 0 ]]; then
            echo "${dep} not found, do you want to install it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                opm get ${dep} > /dev/null && echo "${dep} successfully installed"
            else
                echo "unable to continue without ${dep}. Exiting" && exit 1
            fi      
        fi
    done
}


install() {
    mkdir -p ${DATA_PATH}/templates/

    cp -r lua/lib/* ${LIB_PATH}/
    cp templates/* ${DATA_PATH}/templates/
    #Patch the nginx config file
    SSL_CERTS_PATH=${SSL_CERTS_PATH} envsubst < openresty/${NGINX_CONF} > "${NGINX_CONF_DIR}/${NGINX_CONF}"
    sed -i 's|/etc/crowdsec/bouncers|'${CONFIG_PATH}'|' "${NGINX_CONF_DIR}/${NGINX_CONF}"
}


if ! [ $(id -u) = 0 ] && [ -z ${DOCKER} ]; then
    log_err "Please run the install script as root or with sudo"
    exit 1
fi

#Fix paths
[ -z ${DOCKER} ] && check_pkg_manager
requirement
[ -z ${DOCKER} ] && check_openresty_dependency
[ -z ${DOCKER} ] && check_lua_dependency
gen_config_file
install
echo "crowdsec-openresty-bouncer installed successfully"
[ -z ${DOCKER} ] && echo "Run 'sudo systemctl restart openresty.service' to start openresty-bouncer"