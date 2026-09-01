FROM ubuntu:22.04
LABEL org.opencontainers.image.authors="frantsuzov_v_p@student.sechenov.ru" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.description="Task_2"

ENV SOFT=/soft

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    curl \
    ca-certificates \
    cmake \
    && rm -rf /var/lib/apt/lists/*

    # libdeflate v1.26, 2026-08-22
RUN curl -OL https://github.com/ebiggers/libdeflate/releases/download/v1.26/libdeflate-1.26.tar.gz \
    && tar -xzf libdeflate-1.26.tar.gz \
    && cmake -B build -S ./libdeflate-1.26 -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate-1.26 \
    && cmake --build build -j$(nproc) \
    && cmake --install build \
    && rm -rf ./libdeflate* ./build
