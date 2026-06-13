FROM node:26-alpine3.23

RUN mkdir /root/.pi && \
    apk add curl bash python3 && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.79.1 && \
    pi install npm:tau-mirror

# Fix: https://github.com/deflating/tau/pull/37
# Broken /api/instances handler has empty block with no closing brace,
# cascading into all subsequent route handlers being nested inside it.
COPY patch-tau-mirror.py /tmp/patch-tau-mirror.py
RUN python3 /tmp/patch-tau-mirror.py /root/.pi/agent/npm/node_modules/tau-mirror/extensions/mirror-server.ts

WORKDIR /root

CMD ["pi", "-p"]
