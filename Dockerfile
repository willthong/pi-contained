FROM node:26-alpine3.23

RUN mkdir /root/.pi && \
    apk add curl bash git ripgrep python3 make g++ linux-headers && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@1.2.0 && \
    npm install -g @jmfederico/pi-web --allow-scripts=node-pty && \
    chmod +x /usr/local/bin/pi-web /usr/local/bin/pi-web-server /usr/local/bin/pi-web-sessiond

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root/projects

ENTRYPOINT ["/entrypoint.sh"]
