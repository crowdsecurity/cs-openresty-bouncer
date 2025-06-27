#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/plugins/crowdsec/"
PKG="apt"
PACKAGE_LIST="dpkg -l"
SILENT="false"

#Accept cmdline arguments to overwrite options.
while [[ $# -gt 0 ]]
do
    case $1 in
        -y|--yes)
            SILENT="true"
        ;;
    esac
    shift
done

check_pkg_manager(){
    if [ -f /etc/redhat-release ]; then
        PKG="yum remove"
        PACKAGE_LIST="yum list installed"
    elif [ -f /etc/system-release ]; then
        if grep -q "Amazon Linux release 2 (Karoo)" < /etc/system-release ; then
            PKG="yum remove"
            PACKAGE_LIST="yum list installed"
        fi
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
        "ledgetech/lua-resty-http"
    )
    for dep in ${DEPENDENCY[@]};
    do
        opm list | grep ${dep} > /dev/null
        if [[ $? == 0 ]]; then
            if [[ ${SILENT} == "true" ]]; then
                opm remove ${dep} > /dev/null && echo "${dep} successfully removed"
            else
                echo "${dep} found, do you want to remove it (Y/n)? "
                read answer
                if [[ ${answer} == "" ]]; then
                    answer="y"
                fi
                if [ "$answer" != "${answer#[Yy]}" ] ;then
                    opm remove ${dep} > /dev/null && echo "${dep} successfully removed"
                fi
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
            if [[ ${SILENT} == "true" ]]; then
                $PKG -y -qq ${dep} > /dev/null && echo "${dep} successfully removed"
            else
                echo "${dep} found, do you want to remove it (Y/n)? "
                read answer
                if [[ ${answer} == "" ]]; then
                    answer="y"
                fi
                if [ "$answer" != "${answer#[Yy]}" ] ;then
                    $PKG -y -qq ${dep} > /dev/null && echo "${dep} successfully removed"
                fi
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
echo ""
echo "Don't forget to remove 'include /usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf;' in your nginx configuration file to disable the bouncer and make openresty start again."
echo ""
echo "Run 'sudo systemctl restart openresty.service' to stop openresty-bouncer"