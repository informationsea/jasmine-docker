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

FROM eclipse-temurin:25
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl tar python3 xz-utils bzip2 libcurl4 libncursesw6 libssl3 zlib1g liblzma5 libbz2-1.0 && rm -rf /var/lib/apt/lists/*
WORKDIR /software
ARG JASMINE_VERSION=1.1.5
RUN curl -L https://github.com/mkirsche/Jasmine/archive/refs/tags/v${JASMINE_VERSION}.tar.gz|tar xz
ENV PATH="/software/Jasmine-${JASMINE_VERSION}:${PATH}"
COPY --from=samtools-build /usr/local /usr/local
COPY --from=bcftools-build /usr/local /usr/local
COPY --from=htslib-build /usr/local /usr/local
