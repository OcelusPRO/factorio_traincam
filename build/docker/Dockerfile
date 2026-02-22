FROM alpine:latest
RUN apk add --no-cache bash zip jq
WORKDIR /build

COPY build.sh .

CMD ["/bin/bash", "./build.sh"]