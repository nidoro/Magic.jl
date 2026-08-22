FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf automake libtool m4 \
    flex bison gettext autopoint \
    g++ \
    cmake \
    git \
    pkg-config \
    ca-certificates \
    curl \
    wget \
    zlib1g-dev \
    gawk \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
