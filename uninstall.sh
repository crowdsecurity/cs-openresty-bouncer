#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/crowdsec/"

remove_lua_dependency() {
    DEPENDENCY=(
        "pintsized/lua-resty-http"
    )
    for dep in ${DEPENDENCY[@]};
    do
        opm list | grep ${dep} > /dev/null
        if [[ $? == 0 ]]; then
            echo "${dep} found, do you want to remove it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                opm remove ${dep} > /dev/null && echo "${dep} successfully removed"
            fi      
        fi
    done
}

remove_openresty_dependency() {
    DEPENDENCY=(
        "openresty-opm"
    )
    for dep in ${DEPENDENCY[@]};
    do
        dpkg -l | grep ${dep} > /dev/null
        if [[ $? == 0 ]]; then
            echo "${dep} found, do you want to remove it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                apt-get remove --purge -y -qq ${dep} > /dev/null && echo "${dep} successfully removed"
            fi      
        fi
    done
}


uninstall() {
    rm -rf ${LIB_PATH}
	rm ${NGINX_CONF_DIR}/${NGINX_CONF}
}

if ! [ $(id -u) = 0 ]; then
    log_err "Please run the uninstall script as root or with sudo"
    exit 1
fi
remove_lua_dependency
remove_openresty_dependency
uninstall
echo "crowdsec-openresty-bouncer uninstalled successfully"
echo "Run 'sudo systemctl restart openresty.service' to stop openresty-bouncer"