ARG BUILD_ENV=git
FROM openresty/openresty:alpine-fat as with_deps
RUN luarocks install lua-resty-http

FROM with_deps as git
ARG BUILD_ENV=git
ARG LUA_LIB_VERSION=v1.0.0
RUN if [ "$BUILD_ENV" == "git" ]; then apk add --no-cache git; fi
RUN if [ "$BUILD_ENV" == "git" ]; then git clone -b "${LUA_LIB_VERSION}" https://github.com/crowdsecurity/lua-cs-bouncer.git ; fi

FROM with_deps as local
RUN if [ "$BUILD_ENV" == "local" ]; then COPY ./lua-cs-bouncer/ lua-cs-bouncer; fi

FROM ${BUILD_ENV}
RUN apk add bash
RUN mkdir -p /etc/crowdsec/bouncers/ /var/lib/crowdsec/lua/templates/
RUN cp -R lua-cs-bouncer/lib/* /usr/local/openresty/lualib/
RUN cp -R lua-cs-bouncer/templates/* /var/lib/crowdsec/lua/templates/
RUN cp lua-cs-bouncer/config_example.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf ./lua-cs-bouncer/
COPY ./openresty /tmp
RUN SSL_CERTS_PATH=/etc/ssl/certs/ca-certificates.crt envsubst '$SSL_CERTS_PATH' < /tmp/crowdsec_openresty.conf > /etc/nginx/conf.d/crowdsec_openresty.conf
RUN sed -i '1 i\resolver local=on ipv6=off;' /etc/nginx/conf.d/crowdsec_openresty.conf
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/bash docker_start.sh
