#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/plugins/crowdsec/"
PKG="apt"
PACKAGE_LIST="dpkg -l"

check_pkg_manager(){
    if [ -f /etc/redhat-release ]; then
        PKG="yum remove"
        PACKAGE_LIST="yum list installed"
    elif cat /etc/system-release | grep -q "Amazon Linux release 2 (Karoo)"; then
        PKG="yum remove"
        PACKAGE_LIST="yum list installed"
    elif [ -f /etc/debian_version ]; then
        PKG="apt remove --purge"
        PACKAGE_LIST="dpkg -l"
    else
        echo "Distribution is not supported, exiting."
        exit
    fi   
}

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
        $PACKAGE_LIST | grep ${dep} > /dev/null
        if [[ $? == 0 ]]; then
            echo "${dep} found, do you want to remove it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                $PKG -y -qq ${dep} > /dev/null && echo "${dep} successfully removed"
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

check_pkg_manager
remove_lua_dependency
remove_openresty_dependency
uninstall
echo "crowdsec-openresty-bouncer uninstalled successfully"
echo "Run 'sudo systemctl restart openresty.service' to stop openresty-bouncer"