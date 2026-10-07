FROM node:26-alpine3.23

RUN mkdir /root/.pi && \
    apk add curl bash git ripgrep python3 && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@1.0.4

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root/projects

ENTRYPOINT ["/entrypoint.sh"]
