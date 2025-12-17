FROM eclipse-temurin:25
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl tar python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /software
ARG JASMINE_VERSION=1.1.5
RUN curl -L https://github.com/mkirsche/Jasmine/archive/refs/tags/v${JASMINE_VERSION}.tar.gz|tar xz
ENV PATH="/software/Jasmine-${JASMINE_VERSION}:${PATH}"
