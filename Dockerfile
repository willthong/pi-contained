FROM node:26-alpine3.23

RUN mkdir /home/.pi && \
    apk add curl bash && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@0.79.1 && \
    pi install npm:tau-mirror

WORKDIR /home/pi

CMD ["pi"]
