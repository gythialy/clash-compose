FROM golang:latest as clash-builder

# ENV GOPROXY=https://goproxy.cn

RUN wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz -O /tmp/GeoLite2-Country.tar.gz && \
    tar zxvf /tmp/GeoLite2-Country.tar.gz -C /tmp && \
    mv /tmp/GeoLite2-Country_*/GeoLite2-Country.mmdb /Country.mmdb

WORKDIR /clash-src

RUN git clone -b dev https://github.com/Dreamacro/clash.git . && \
    go mod download && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags '-w -s' -o /clash

FROM node:lts-stretch as dashboard-builder

WORKDIR /dashboard-src

RUN git clone https://github.com/Dreamacro/clash-dashboard.git . 

ENV PATH /dashboard-src/node_modules/.bin:$PATH

# RUN apt-get update && apt-get install -y webp && \
#     npm i -g npm --registry=https://registry.npm.taobao.org && \
#     npm ci --registry=https://registry.npm.taobao.org && npm run build

RUN apt-get update && apt-get install -y webp && \
    npm i -g npm  && npm ci  && npm run build

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=clash-builder /Country.mmdb /root/.config/clash/
COPY --from=clash-builder /clash /
COPY --from=dashboard-builder /dashboard-src/dist /dashboard

EXPOSE 7890 7891 7892 9090

ENTRYPOINT ["/clash"]

