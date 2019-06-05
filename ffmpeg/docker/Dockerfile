FROM ubuntu:18.04

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential pkg-config \
    software-properties-common \
    curl git man mc vim nano rsync \
    && \
  rm -rf /var/lib/apt/lists/*

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cmake texinfo yasm bison subversion cvs m4 flex pax ninja-build \
    && \
  rm -rf /var/lib/apt/lists/*

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    mingw-w64 g++-mingw-w64-x86-64 g++-mingw-w64-i686 yasm nasm \
    && \
  rm -rf /var/lib/apt/lists/*

CMD ["/app/docker/entry.sh"]
