FROM node:26-alpine3.23

RUN mkdir /root/.pi && \
    apk add curl bash ripgrep python3 && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.79.1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/entrypoint.sh"]
