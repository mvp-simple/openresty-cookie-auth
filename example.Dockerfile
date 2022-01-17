FROM usmanovrinat1984/openresty_cookie_auth:latest
ENV DB_HOST 172.17.0.3
ENV DB_PORT 5432
ENV DB_NAME pr
ENV DB_USER postgres
ENV DB_PASS mysecretpassword
RUN export DB_HOST="172.17.0.3"
RUN export DB_PORT="5432"
RUN export DB_NAME="pr"
RUN export DB_USER="postgres"
RUN export DB_PASS="mysecretpassword"
CMD nginx -p `pwd` -c /etc/nginx/nginx.conf