FROM ubuntu:24.04

ARG STYLUA_VERSION=2.5.2
ARG STYLUA_SHA256=bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl lua-check lua5.2 python3 \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
  -o /tmp/stylua.zip \
  "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/stylua-linux-x86_64.zip" \
  && echo "${STYLUA_SHA256}  /tmp/stylua.zip" | sha256sum -c - \
  && python3 -m zipfile -e /tmp/stylua.zip /usr/local/bin \
  && chmod +x /usr/local/bin/stylua \
  && rm /tmp/stylua.zip

WORKDIR /workspace

ENV REQUIRE_LUA_TOOLS=1
ENV LUAC=luac5.2

CMD ["scripts/lint-lua.sh"]
