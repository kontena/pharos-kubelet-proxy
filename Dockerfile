FROM nginx:1.13.12-alpine

RUN apk update && apk add bash

ADD run.sh /

ENTRYPOINT ["/run.sh"]
