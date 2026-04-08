FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    luajit \
    lua-socket \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY deploy/web /app/web
COPY deploy/lib /app/lib
COPY deploy/hooks /app/hooks
COPY deploy/neural /app/neural

EXPOSE 8080
CMD ["luajit", "/app/web/server.lua"]
