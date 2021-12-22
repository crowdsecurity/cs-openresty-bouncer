FROM openresty/openresty:alpine-fat

RUN luarocks install lua-resty-http
RUN mkdir -p /usr/local/openresty/lualib/plugins/
COPY ./lua /usr/local/openresty/lualib/plugins/crowdsec
COPY ./config/template.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
COPY ./openresty /etc/nginx/conf.d
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/bash docker_start.sh