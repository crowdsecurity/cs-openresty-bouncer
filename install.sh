#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/plugins/crowdsec/"
CONFIG_PATH="/etc/crowdsec/bouncers/"

requirement() {
    mkdir -p "${CONFIG_PATH}"
    mkdir -p "${NGINX_CONF_DIR}"
    mkdir -p "${LIB_PATH}"
}

gen_config_file() {
    SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
    API_KEY=`cscli bouncers add crowdsec-openresty-bouncer-${SUFFIX} -o raw`
    API_KEY=${API_KEY} CROWDSEC_LAPI_URL="http://127.0.0.1:8080" envsubst < ./config/template.conf > "${CONFIG_PATH}crowdsec-openresty-bouncer.conf"
}

check_openresty_dependency() {
    DEPENDENCY=(
        "openresty-opm"
    )
    for dep in ${DEPENDENCY[@]};
    do
        dpkg -l | grep ${dep} > /dev/null
        if [[ $? != 0 ]]; then
            echo "${dep} not found, do you want to install it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                apt-get install -y -qq ${dep} > /dev/null && echo "${dep} successfully installed"
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
    cp lua/* ${LIB_PATH}
	cp openresty/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
}


if ! [ $(id -u) = 0 ]; then
    log_err "Please run the install script as root or with sudo"
    exit 1
fi
requirement
check_openresty_dependency
check_lua_dependency
gen_config_file
install
echo "crowdsec-openresty-bouncer installed successfully"
echo "Run 'sudo systemctl restart openresty.service' to start openresty-bouncer"