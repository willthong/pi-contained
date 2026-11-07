FROM node:26-alpine3.23

# Pinned versions. Bump deliberately.
ARG PI_VERSION=1.5.0
ARG PASEO_VERSION=0.15.3

# coreutils: Paseo's launcher uses `#!/usr/bin/env -S`, which BusyBox env rejects.
# python3/make/g++/linux-headers: node-pty ships no musl prebuild, so it is
# compiled from source below (npm_config_build_from_source).
# github-cli: `gh`, used by Paseo for GitHub diff/PR views.
RUN mkdir /root/.pi && \
    apk add curl bash git ripgrep jq github-cli python3 make g++ linux-headers coreutils && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION} && \
    npm_config_build_from_source=true npm install -g @getpaseo/cli@${PASEO_VERSION} \
        --allow-scripts=node-pty,esbuild,msgpackr-extract

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root/projects

ENTRYPOINT ["/entrypoint.sh"]
