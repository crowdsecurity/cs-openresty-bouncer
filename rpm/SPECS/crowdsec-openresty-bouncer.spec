Name:           crowdsec-openresty-bouncer
Version:        %(echo $VERSION)
Release:        %(echo $PACKAGE_NUMBER)%{?dist}
Summary:        OpenResty bouncer for Crowdsec

License:        MIT
URL:            https://crowdsec.net
Source0:        https://github.com/crowdsecurity/%{name}/archive/v%(echo $VERSION).tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  git
BuildRequires:  make
%{?fc33:BuildRequires: systemd-rpm-macros}

Requires: openresty, gettext, ca-certificates

%define debug_package %{nil}

%description

%define version_number  %(echo $VERSION)
%define releasever  %(echo $RELEASEVER)
%global local_version v%{version_number}-%{releasever}-rpm
%global name crowdsec-openresty-bouncer
%global __mangle_shebangs_exclude_from /usr/bin/env

%prep
%setup -q -T -b 0 -n crowdsec-openresty-bouncer-%{version_number}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/local/openresty/nginx/conf/conf.d/
mkdir -p %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/
mkdir -p %{buildroot}/var/lib/crowdsec/lua/templates/
mkdir -p %{buildroot}/etc/crowdsec/bouncers/
git clone -b v1.0.19 https://github.com/crowdsecurity/lua-cs-bouncer.git
install -m 600 -D lua-cs-bouncer/config_example.conf %{buildroot}/etc/crowdsec/bouncers/%{name}.conf
install -m 644 -D lua-cs-bouncer/lib/crowdsec.lua %{buildroot}/usr/local/openresty/lualib/
install -m 644 -D lua-cs-bouncer/lib/plugins/crowdsec/* %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/
mkdir -p %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/resty/
install -m 644 -D vendor/*/lib/resty/* %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/resty/
install -m 644 -D lua-cs-bouncer/templates/* %{buildroot}/var/lib/crowdsec/lua/templates/
install -m 644 -D openresty/crowdsec_openresty.conf %{buildroot}/usr/local/openresty/nginx/conf/conf.d/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/usr/local/openresty/lualib/
/var/lib/crowdsec/lua/templates/
/usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf
%config(noreplace) /etc/crowdsec/bouncers/%{name}.conf


%post -p /bin/bash

systemctl daemon-reload

NGINX_CONFIG_PATH="/usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf"
BOUNCER_CONFIG_PATH="/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf"
START=0
LAPI_DEFAULT_PORT="8080"

# The same RPM is installed on every RPM-based distro, so the CA bundle is
# looked up on the host. This runs on upgrades too: the nginx config is not
# a %config file and is replaced by the template on every upgrade.
CERTS=(
    "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
    "/var/lib/ca-certificates/ca-bundle.pem"
    "/etc/ssl/ca-bundle.pem"
    "/etc/pki/tls/certs/ca-bundle.crt"
    "/etc/ssl/certs/ca-bundle.crt"
)
CERT_FILE=""
for cert_path in "${CERTS[@]}"; do
    if [ -f "$cert_path" ]; then
        CERT_FILE=$cert_path
        break
    fi
done
if [ -n "$CERT_FILE" ]; then
    sed -i "s|\${SSL_CERTS_PATH}|${CERT_FILE}|" ${NGINX_CONFIG_PATH}
else
    sed -i 's|^lua_ssl_trusted_certificate \${SSL_CERTS_PATH};|# lua_ssl_trusted_certificate <CA bundle path>;|' ${NGINX_CONFIG_PATH}
    echo "Unable to find a CA bundle: 'lua_ssl_trusted_certificate' is commented out in ${NGINX_CONFIG_PATH}, set it to enable TLS certificate verification."
fi

if [ "$1" == "1" ] ; then
    type cscli > /dev/null
    if [ "$?" -eq "0" ] ; then
        START=1
        echo "cscli/crowdsec is present, generating API key"
        unique=`date +%s`
        API_KEY=`cscli -oraw bouncers add crowdsec-openresty-bouncer-${unique}`
        PORT=$(cscli config show --key "Config.API.Server.ListenURI"|cut -d ":" -f2)
        if [ ! -z "$PORT" ]; then
            LAPI_DEFAULT_PORT=${PORT}
        fi
        CROWDSEC_LAPI_URL="http://127.0.0.1:${LAPI_DEFAULT_PORT}"
        if [ $? -eq 1 ] ; then
            echo "failed to create API token, service won't be started."
            START=0
            API_KEY="<API_KEY>"
        else
            echo "API Key : ${API_KEY}"
        fi
        TMP=`mktemp -p /tmp/`
        cp ${BOUNCER_CONFIG_PATH} ${TMP}
        API_KEY=${API_KEY} CROWDSEC_LAPI_URL=${CROWDSEC_LAPI_URL} envsubst < ${TMP} > ${BOUNCER_CONFIG_PATH}
        rm ${TMP}
    fi

    echo "Add 'include /usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf;' in your nginx configuration file (in the 'http' section) to enable the bouncer."

else 
    START=1
fi

echo "CrowdSec OpenResty Bouncer installed. Restart OpenResty service with 'sudo systemctl restart openresty'"

%postun -p /bin/bash
if [ "$1" == "0" ] ; then
    echo "Don't forget to remove 'include /usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf;' in your nginx configuration file to disable the bouncer and make openresty start again."
    echo ""
    echo "Run 'sudo systemctl restart openresty.service' to stop openresty-bouncer"
fi
 
%changelog
* Tue Feb 1 2022 Kevin Kadosh <kevin@crowdsec.net>
- First initial packaging
