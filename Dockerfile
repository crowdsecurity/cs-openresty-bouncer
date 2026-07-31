ARG BUILD_ENV=git

FROM docker.io/openresty/openresty:alpine-fat AS with_deps
RUN luarocks install lua-resty-http 0.17.1-0

FROM with_deps AS git
ARG LUA_LIB_VERSION=v1.0.16
RUN apk add --no-cache git
RUN git clone -b "${LUA_LIB_VERSION}" https://github.com/crowdsecurity/lua-cs-bouncer.git /lua-cs-bouncer

FROM with_deps AS local
COPY lua-cs-bouncer/ /lua-cs-bouncer/

FROM ${BUILD_ENV} AS final
# (optional, if you want to use it in RUN steps)
ARG BUILD_ENV

RUN mkdir -p /etc/crowdsec/bouncers/ /var/lib/crowdsec/lua/templates/
RUN cp -R /lua-cs-bouncer/lib/* /usr/local/openresty/lualib/
RUN cp -R /lua-cs-bouncer/templates/* /var/lib/crowdsec/lua/templates/
RUN cp /lua-cs-bouncer/config_example.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf /lua-cs-bouncer

COPY openresty /tmp
RUN SSL_CERTS_PATH=/etc/ssl/certs/ca-certificates.crt envsubst '$SSL_CERTS_PATH' < /tmp/crowdsec_openresty.conf > /etc/nginx/conf.d/crowdsec_openresty.conf
RUN sed -i '1 i\resolver local=on ipv6=off;' /etc/nginx/conf.d/crowdsec_openresty.conf
COPY docker/docker_start.sh /

ENTRYPOINT ["/bin/sh", "docker_start.sh"]