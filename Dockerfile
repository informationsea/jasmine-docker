FROM ubuntu:24.04 AS download
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl tar xz-utils bzip2
ARG SAMTOOLS_VERSION=1.23
ARG BCFTOOLS_VERSION=1.23
ARG HTSLIB_VERSION=1.23
RUN curl -fOL https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2
RUN curl -fOL https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2
RUN curl -fOL https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2
RUN tar xjf samtools-${SAMTOOLS_VERSION}.tar.bz2
RUN tar xjf bcftools-${BCFTOOLS_VERSION}.tar.bz2
RUN tar xjf htslib-${HTSLIB_VERSION}.tar.bz2

FROM ubuntu:24.04 AS buildenv
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl tar xz-utils bzip2 build-essential libssl-dev libcurl4-openssl-dev zlib1g-dev libbz2-dev liblzma-dev

FROM buildenv AS samtools-build
RUN apt-get install -y libncurses-dev
ARG SAMTOOLS_VERSION=1.23
COPY --from=download /samtools-${SAMTOOLS_VERSION} /samtools-${SAMTOOLS_VERSION}
WORKDIR /samtools-${SAMTOOLS_VERSION}
RUN ./configure && make -j4 && make install

FROM buildenv AS bcftools-build
RUN apt-get install -y libncurses-dev
ARG BCFTOOLS_VERSION=1.23
COPY --from=download /bcftools-${BCFTOOLS_VERSION} /bcftools-${BCFTOOLS_VERSION}
WORKDIR /bcftools-${BCFTOOLS_VERSION}
RUN ./configure && make -j4 && make install

FROM buildenv AS htslib-build
ARG HTSLIB_VERSION=1.23
COPY --from=download /htslib-${HTSLIB_VERSION} /htslib-${HTSLIB_VERSION}
WORKDIR /htslib-${HTSLIB_VERSION}
RUN ./configure && make -j4 && make install

FROM buildenv AS minimap2
WORKDIR /minimap2
ARG MINIMAP2_VERSION=2.30
RUN curl -OL https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_VERSION}/minimap2-${MINIMAP2_VERSION}_x64-linux.tar.bz2
RUN tar xjf minimap2-${MINIMAP2_VERSION}_x64-linux.tar.bz2
WORKDIR /minimap2/minimap2-${MINIMAP2_VERSION}_x64-linux
RUN cp minimap2 k8 paftools.js /usr/local/bin/ && \
    chmod +x /usr/local/bin/minimap2 /usr/local/bin/k8 /usr/local/bin/paftools.js && \
    cp minimap2.1 /usr/share/man/man1/minimap2.1 && \
    mkdir -p /usr/local/share/doc/minimap2 && \
    cp README.md cookbook.md NEWS.md README-js.md /usr/local/share/doc/minimap2/

FROM buildenv AS racon
WORKDIR /racon
ARG RACON_VERSION=1.4.3
RUN curl -OL https://github.com/isovic/racon/releases/download/${RACON_VERSION}/racon-v${RACON_VERSION}.tar.gz
RUN tar xzf racon-v${RACON_VERSION}.tar.gz
WORKDIR /racon/racon-v${RACON_VERSION}
RUN apt-get install -y cmake
RUN cmake -DCMAKE_BUILD_TYPE=Release -B build && \
    cmake --build build && cmake --install build

FROM eclipse-temurin:25
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl tar python3 xz-utils bzip2 libcurl4 libncursesw6 libssl3 zlib1g liblzma5 libbz2-1.0 python3-cyvcf2 && rm -rf /var/lib/apt/lists/*
WORKDIR /software
ARG JASMINE_VERSION=1.1.5
RUN curl -L https://github.com/mkirsche/Jasmine/archive/refs/tags/v${JASMINE_VERSION}.tar.gz|tar xz
RUN curl -L -o /usr/local/bin/mosdepth https://github.com/brentp/mosdepth/releases/download/v0.3.12/mosdepth && chmod 755 /usr/local/bin/mosdepth
ENV PATH="/software/Jasmine-${JASMINE_VERSION}:${PATH}"
COPY --from=samtools-build /usr/local /usr/local
COPY --from=bcftools-build /usr/local /usr/local
COPY --from=htslib-build /usr/local /usr/local
COPY --from=minimap2 /usr/local /usr/local
COPY --from=racon /usr/local /usr/local
COPY sv_sizes.py /usr/local/bin/sv_sizes.py
COPY sv_supports.py /usr/local/bin/sv_supports.py
RUN chmod +x /usr/local/bin/sv_sizes.py /usr/local/bin/sv_supports.py