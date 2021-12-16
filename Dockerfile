FROM openresty/openresty:alpine-fat

RUN luarocks install lua-resty-http