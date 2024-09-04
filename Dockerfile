ARG BUILD_ENV=git
FROM openresty/openresty:alpine-fat AS with_deps
RUN luarocks install lua-resty-http

FROM with_deps AS git
ARG BUILD_ENV=git
RUN if [ "$BUILD_ENV" == "git" ]; then apk add --no-cache git; fi
RUN if [ "$BUILD_ENV" == "git" ]; then git clone https://github.com/crowdsecurity/lua-cs-bouncer.git ; fi

FROM with_deps AS local
RUN if [ "$BUILD_ENV" == "local" ]; then COPY ./lua-cs-bouncer/ lua-cs-bouncer; fi

FROM ${BUILD_ENV}
RUN mkdir -p /etc/crowdsec/bouncers/ /var/lib/crowdsec/lua/templates/
RUN cp -R lua-cs-bouncer/lib/* /usr/local/openresty/lualib/
RUN cp -R lua-cs-bouncer/templates/* /var/lib/crowdsec/lua/templates/
RUN cp lua-cs-bouncer/config_example.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf ./lua-cs-bouncer/
COPY ./openresty /tmp
RUN SSL_CERTS_PATH=/etc/ssl/certs/ca-certificates.crt envsubst '$SSL_CERTS_PATH' < /tmp/crowdsec_openresty.conf > /etc/crowdsec/bouncers/crowdsec_openresty_lua.conf
RUN sed -i '1 i\resolver local=on ipv6=off;' /etc/crowdsec/bouncers/crowdsec_openresty_lua.conf
RUN sed -i '/^http {/,/^}/!b;/^}/i\\n    include \/etc\/crowdsec\/bouncers\/crowdsec_openresty_lua.conf;' /usr/local/openresty/nginx/conf/nginx.conf
COPY ./docker/docker_start.sh /


ENTRYPOINT /bin/bash docker_start.sh
