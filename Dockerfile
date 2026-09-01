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
    libncurses5-dev \
    curl \
    ca-certificates \
    cmake \
    automake \
    perl \
    && rm -rf /var/lib/apt/lists/*

    # libdeflate v1.26, 2026-08-22
RUN curl -OL https://github.com/ebiggers/libdeflate/releases/download/v1.26/libdeflate-1.26.tar.gz \
    && tar -xzf libdeflate-1.26.tar.gz \
    && cmake -B build -S ./libdeflate-1.26 -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate-1.26 \
    && cmake --build build -j$(nproc) \
    && cmake --install build \
    && rm -rf ./libdeflate* ./build

ENV PATH=$SOFT/libdeflate-1.26/bin:$PATH \ 
    LD_LIBRARY_PATH=$SOFT/libdeflate-1.26/lib \
    LIBDEFLATEGZIP=$SOFT/libdeflate-1.26/bin/libdeflate-gzip \
    LIBDEFLATEGUNZIP=$SOFT/libdeflate-1.26/bin/libdeflate-gunzip

    # htslib 1.24, 2026-07-09
RUN curl -OL https://github.com/samtools/htslib/releases/download/1.24/htslib-1.24.tar.bz2 \
    && tar -xjf htslib-1.24.tar.bz2 \
    && cd htslib-1.24/ \
    && ./configure CPPFLAGS="-I$SOFT/libdeflate-1.26/include" LDFLAGS="-L$SOFT/libdeflate-1.26/lib" --prefix=$SOFT/htslib-1.24  \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf ./hts*

ENV PATH=$SOFT/htslib-1.24/bin:$PATH \
    LD_LIBRARY_PATH=$SOFT/htslib-1.24/lib:$LD_LIBRARY_PATH \
    ANNOTTSV=$SOFT/htslib-1.24/bin/annot-tsv \
    BGZIP=$SOFT/htslib-1.24/bin/bgzip \
    HTSFILE=$SOFT/htslib-1.24/bin/htsfile \
    REFCACHE=$SOFT/htslib-1.24/bin/ref-cache \
    TABIX=$SOFT/htslib-1.24/bin/tabix

    # samtools 1.24, 2026-07-09
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.24/samtools-1.24.tar.bz2 \
    && tar -xjf samtools-1.24.tar.bz2 \
    && cd samtools-1.24/ \
    && ./configure --with-htslib=$SOFT/htslib-1.24/  --prefix=$SOFT/samtools-1.24  \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf ./sam*

ENV PATH=$SOFT/samtools-1.24/bin:$PATH \
    SAMTOOLS=$SOFT/samtools-1.24/bin/samtools
