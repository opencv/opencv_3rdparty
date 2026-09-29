FROM ubuntu:24.04

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
    wget xz-utils yasm nasm \
    && \
  rm -rf /var/lib/apt/lists/*

RUN \
  wget -q https://github.com/mstorsjo/llvm-mingw/releases/download/20240606/llvm-mingw-20240606-msvcrt-ubuntu-20.04-x86_64.tar.xz && \
  tar -xf llvm-mingw-20240606-msvcrt-ubuntu-20.04-x86_64.tar.xz -C /opt && \
  rm llvm-mingw-*.tar.xz && \
  mv /opt/llvm-mingw-* /opt/llvm-mingw

ENV PATH="/opt/llvm-mingw/bin:${PATH}"

USER ubuntu

CMD ["/app/docker/entry.sh"]
