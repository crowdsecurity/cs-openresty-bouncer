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

Requires: openresty, openresty-opm, gettext

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
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/usr/local/openresty/nginx/conf/conf.d/
mkdir -p %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/
mkdir -p %{buildroot}/var/lib/crowdsec/lua/templates/
mkdir -p %{buildroot}/etc/crowdsec/bouncers/
git clone https://github.com/crowdsecurity/lua-cs-bouncer.git
install -m 600 -D lua-cs-bouncer/config_example.conf %{buildroot}/etc/crowdsec/bouncers/%{name}.conf
install -m 644 -D lua-cs-bouncer/lib/crowdsec.lua %{buildroot}/usr/local/openresty/lualib/
install -m 644 -D lua-cs-bouncer/lib/plugins/crowdsec/* %{buildroot}/usr/local/openresty/lualib/plugins/crowdsec/
install -m 644 -D lua-cs-bouncer/templates/* %{buildroot}/var/lib/crowdsec/lua/templates/
install -m 644 -D openresty/crowdsec_openresty.conf %{buildroot}/usr/local/openresty/nginx/conf/conf.d/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/usr/bin/%{name}
/usr/local/openresty/lualib/
/usr/local/openresty/nginx/conf/conf.d/crowdsec_openresty.conf
%config(noreplace) /etc/crowdsec/bouncers/%{name}.conf


%post -p /bin/bash

systemctl daemon-reload

BOUNCER_CONFIG_PATH="/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf"
START=0

check_lua_dependency() {
    DEPENDENCY=(
        "pintsized/lua-resty-http"
    )
    for dep in ${DEPENDENCY[@]};
    do
        opm list | grep ${dep} > /dev/null
        if [[ $? != 0 ]]; then
            opm get ${dep} > /dev/null && echo "${dep} successfully installed"     
        fi
    done
}


if [ "$1" == "1" ] ; then
    type cscli > /dev/null

    if [ "$?" -eq "0" ] ; then
        # Check if it's an upgrade
        if [ "$2" != "" ] ; then
            echo "Upgrading, check if there is bouncer configuration"
            if [ -f "${BOUNCER_CONFIG_PATH}" ] ; then
                START=2
            fi
        fi
        if [ ${START} -eq 0 ] ; then
            START=1
            echo "cscli/crowdsec is present, generating API key"
            unique=`date +%s`
            API_KEY=`cscli -oraw bouncers add crowdsec-openresty-bouncer-${unique}`
            CROWDSEC_LAPI_URL="http://127.0.0.1:8080"
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
        check_lua_dependency
    fi
else 
    START=1
fi

echo "CrowdSec OpenResty Bouncer installed. Restart openresty service with 'sudo systemctl restart openresty'"

 
%changelog
* Tue Feb 1 2022 Kevin Kadosh <kevin@crowdsec.net>
- First initial packaging
