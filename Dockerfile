FROM openresty/openresty:alpine-fat

RUN luarocks install lua-resty-http
COPY ./lua /usr/local/openresty/lualib/crowdsec
COPY ./config/template.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
COPY ./openresty /etc/nginx/conf.d
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/sh docker_start.sh