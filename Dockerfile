FROM openresty/openresty:alpine-fat

RUN apk add --no-cache git
RUN luarocks install lua-resty-http
RUN git clone https://github.com/crowdsecurity/lua-cs-bouncer.git
RUN mkdir -p /usr/local/openresty/lualib/plugins/crowdsec/ /etc/crowdsec/bouncers/
RUN cp lua-cs-bouncer/nginx/*.lua /usr/local/openresty/lualib/plugins/crowdsec/
RUN cp lua-cs-bouncer/nginx/template.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf ./lua-cs-bouncer/
COPY ./openresty /etc/nginx/conf.d
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/bash docker_start.sh