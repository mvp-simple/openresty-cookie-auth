FROM openresty/openresty:alpine-fat
ENV TZ "Asia/Almaty"
ENV key  "token-key"
RUN apk add postgresql14-dev
RUN apk add --no-cache git
RUN /usr/local/openresty/luajit/bin/luarocks install pgmoon
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-reqargs
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-jwt
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-cors
RUN /usr/local/openresty/luajit/bin/luarocks install luaossl
RUN mkdir -p /logs
RUN touch /logs/access.log
RUN mkdir -p /usr/share/nginx/html/download
RUN mkdir -p /etc/nginx/lua
COPY ./html /usr/share/nginx/html/
COPY ./lua /etc/nginx/lua
COPY ./nginx.conf   /etc/nginx/nginx.conf
COPY conf.d/  /etc/nginx/conf.d/
RUN mkdir /etc/nginx/conf.d/user.conf.d/
