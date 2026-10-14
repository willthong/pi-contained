FROM node:26-alpine3.23

# Pinned Paseo CLI version. Bump deliberately.
ARG PASEO_VERSION=0.11.2

# coreutils: Paseo's launcher uses `#!/usr/bin/env -S`, which BusyBox env rejects.
# python3/make/g++/linux-headers: node-pty ships no musl prebuild, so it is
# compiled from source below (npm_config_build_from_source).
RUN mkdir /root/.pi && \
    apk add curl bash git ripgrep python3 make g++ linux-headers coreutils && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@1.2.0 && \
    npm install -g @jmfederico/pi-web --allow-scripts=node-pty && \
    npm_config_build_from_source=true npm install -g @getpaseo/cli@${PASEO_VERSION} \
        --allow-scripts=node-pty,esbuild,msgpackr-extract && \
    chmod +x /usr/local/bin/pi-web /usr/local/bin/pi-web-server /usr/local/bin/pi-web-sessiond

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root/projects

ENTRYPOINT ["/entrypoint.sh"]
