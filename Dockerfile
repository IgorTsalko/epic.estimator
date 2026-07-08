FROM dpharbor.ftc.ru/docker.io/library/nginx:stable-alpine

COPY --chown=101:101 epic-estimator.html /usr/share/nginx/html-template/index.html
COPY --chown=101:101 config/default.conf /etc/nginx/conf.d/default.conf
COPY --chown=101:101 config/nginx.conf /etc/nginx/nginx.conf
COPY --chown=101:101 config/docker-entrypoint.d/render-config.sh /docker-entrypoint.d/render-config.sh

RUN mkdir -p /var/log/nginx && \
    chown -R 101:101 /var/log/nginx && \
    chmod -R 755 /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R 101:101 /var/cache/nginx && \
    chown -R 101:101 /etc/nginx && \
    chmod -R 755 /etc/nginx && \
    chown -R 101:101 /usr/share/nginx/ && \
    chmod +x /docker-entrypoint.d/render-config.sh

RUN touch /var/run/nginx.pid && \
        chown -R nginx:nginx /var/run/nginx.pid /run/nginx.pid

USER 101:101
EXPOSE 8080