FROM golang:1.13.5 as clash-builder

# ENV GOPROXY=https://goproxy.cn,direct

ENV CLASH_VERSION=v0.17.0

RUN wget -O /Country.mmdb https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb

WORKDIR /clash-src

RUN git clone -b ${CLASH_VERSION} --depth 1 https://github.com/Dreamacro/clash.git /clash-src && \
    go mod download && \
    make linux-amd64 && \
    mv ./bin/clash-linux-amd64 /clash

FROM node:lts-stretch as dashboard-builder

WORKDIR /dashboard-src

RUN git clone --depth 10 https://github.com/Dreamacro/clash-dashboard.git . 

ENV PATH /dashboard-src/node_modules/.bin:$PATH

# RUN apt-get update && apt-get install -y webp && \
#     npm i -g npm --registry=https://registry.npm.taobao.org && \
#     npm ci --registry=https://registry.npm.taobao.org && npm run build

RUN apt-get update && apt-get install -y webp && \
    npm i -g npm && npm ci && npm run build

FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=clash-builder /Country.mmdb /root/.config/clash/
COPY --from=clash-builder /clash /
COPY --from=dashboard-builder /dashboard-src/dist /dashboard

EXPOSE 7890 7891 7892 9090

ENTRYPOINT ["/clash"]

