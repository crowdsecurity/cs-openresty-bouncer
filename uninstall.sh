#!/bin/bash

NGINX_CONF="crowdsec_openresty.conf"
NGINX_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d/"
LIB_PATH="/usr/local/openresty/lualib/plugins/crowdsec/"

#Accept cmdline arguments to overwrite options.
while [[ $# -gt 0 ]]
do
    case $1 in
        -y|--yes)
            # no-op, kept for backward compatibility
        ;;
    esac
    shift
done

check_pkg_manager(){
    if ! [ -f /etc/redhat-release ] && ! [ -f /etc/system-release ] && ! [ -f /etc/debian_version ]; then
        echo "Distribution is not supported, exiting."
        exit
    fi
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
uninstall
echo "crowdsec-openresty-bouncer uninstalled successfully"
echo ""
echo "Don't forget to remove 'include /usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf;' in your nginx configuration file to disable the bouncer and make openresty start again."
echo ""
echo "Run 'sudo systemctl restart openresty.service' to stop openresty-bouncer"