FROM ubuntu:22.04
ARG APP_UID=500
ARG APP_GID=500

ENV APP_UID=$APP_UID
ENV APP_GID=$APP_GID

RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential pkg-config \
    software-properties-common \
    curl git man mc vim nano rsync file wget perl dos2unix python3 python-is-python3 \
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
    clang lld llvm \
    yasm nasm \
    && \
  rm -rf /var/lib/apt/lists/*

RUN \
  wget https://github.com/mstorsjo/llvm-mingw/releases/download/20251202/llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz && \
  tar -xf llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz -C /opt && \
  mv /opt/llvm-mingw-* /opt/llvm-mingw && \
  rm llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz

ENV PATH="/opt/llvm-mingw/bin:${PATH}"

COPY entry.sh /app/docker/entry.sh
RUN chmod +x /app/docker/entry.sh
# CMD [".","app/docker/entry.sh"]
