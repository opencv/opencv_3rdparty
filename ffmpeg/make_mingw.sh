#!/bin/bash -ex
# This file is well tested on Ubuntu
# List of required packages for build see in docker/Dockerfile
# (preferred way is to use Docker to produce similar environment)
#
# This script may not work in MINGW installation on Windows
#
# Usage ${0} <build_dir>
# build directory should be created via download_src.sh script:
#

. ../build/env.sh

CURRENT_DIR=`pwd`
BUILD_DIR=${1:-.}
CPU_COUNT=$(nproc || echo 4)  # use OPENCV_FFMPEG_DOCKER_EXTRA_ARGS="--cpuset-cpus=0,2,4,6,8,10,12,14" to tune

## Libvpx

libvpx_DIR=${BUILD_DIR}/libvpx
libvpx_x86_DIR=${BUILD_DIR}/libvpx_x86
libvpx_x64_DIR=${BUILD_DIR}/libvpx_x64
#[ -d ${libvpx_x86_DIR} ] ||
(
cd ${libvpx_DIR}
mkdir -p ${libvpx_x86_DIR}
rsync -a ./ ${libvpx_x86_DIR} --exclude .git
cd ${libvpx_x86_DIR}
CROSS=i686-w64-mingw32- ./configure --target=x86-win32-gcc ${libvpx_configure_OPTIONS} --prefix=${libvpx_x86_DIR}/install
make -j ${CPU_COUNT}
make install
)
#[ -d ${libvpx_x64_DIR} ] ||
(
cd ${libvpx_DIR}
mkdir -p ${libvpx_x64_DIR}
rsync -a ./ ${libvpx_x64_DIR} --exclude .git
cd ${libvpx_x64_DIR}
CROSS=x86_64-w64-mingw32- ./configure --target=x86_64-win64-gcc ${libvpx_configure_OPTIONS} --prefix=${libvpx_x64_DIR}/install
make -j ${CPU_COUNT}
make install
)

libvpx_ARM64_DIR=${BUILD_DIR}/libvpx_ARM64
libvpx_configure_OPTIONS="--disable-examples --disable-unit-tests --disable-install-bins --disable-docs --disable-shared --enable-static --enable-vp8 --enable-vp9 --disable-multithread"
if [ ! -d ${libvpx_DIR} ]; then
  echo "Libvpx source tree is not found"
  exit 1
fi
#[ -d ${libvpx_ARM64_DIR} ] ||
(
cd /tmp
wget https://github.com/mstorsjo/llvm-mingw/releases/download/20251202/llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz
mkdir -p /app/llvm-mingw
tar -xf llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz -C /app/llvm-mingw --strip-components=1
cd ${libvpx_DIR}
mkdir -p ${libvpx_ARM64_DIR}
rsync -a ./ ${libvpx_ARM64_DIR} --exclude .git
find ${libvpx_ARM64_DIR} -type f \( -name "*.pl" -o -name "*.c" -o -name "*.h" \) -exec dos2unix {} \;

cd ${libvpx_ARM64_DIR}
export PATH=/app/llvm-mingw/bin:$PATH
export CROSS_PREFIX=aarch64-w64-mingw32-
export CC="${CROSS_PREFIX}gcc"
export CXX="${CROSS_PREFIX}g++"
export AR="${CROSS_PREFIX}ar"
export RANLIB="${CROSS_PREFIX}ranlib"
export STRIP="${CROSS_PREFIX}strip"

CROSS=aarch64-w64-mingw32- ./configure \
    --target=arm64-win64-gcc \
    --disable-runtime-cpu-detect \
    ${libvpx_configure_OPTIONS} \
    --prefix=${libvpx_ARM64_DIR}/install

make -j ${CPU_COUNT}
make install
)

## Open264

openh264_x86_DIR=${openh264_DIR}/install_x86
openh264_x86_64_DIR=${openh264_DIR}/install_x86_64
(
 cd ${openh264_DIR}
 if [[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]]; then
  make PREFIX=${openh264_x86_DIR} install-headers
 else
  PREFIX=${openh264_x86_DIR}
  mkdir -p ${PREFIX}/include/wels
  install -m 644 ${openh264_DIR}/codec/api/svc/codec*.h ${PREFIX}/include/wels
 fi
 mkdir -p ${openh264_x86_DIR}/lib/pkgconfig
 i686-w64-mingw32-gcc -m32 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_DIR}/lib/openh264_wrapper.o
 x86_64-w64-mingw32-ar rcs ${openh264_x86_DIR}/lib/libopenh264_wrapper.a ${openh264_x86_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.8
Libs: -L\${prefix}/lib -lopenh264_wrapper
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)
(
 cd ${openh264_DIR}
 if [[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]]; then
  make PREFIX=${openh264_x86_64_DIR} install-headers
 else
  PREFIX=${openh264_x86_64_DIR}
  mkdir -p ${PREFIX}/include/wels
  install -m 644 ${openh264_DIR}/codec/api/svc/codec*.h ${PREFIX}/include/wels
 fi
 mkdir -p ${openh264_x86_64_DIR}/lib/pkgconfig
 x86_64-w64-mingw32-gcc -m64 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_64_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_64_DIR}/lib/openh264_wrapper.o
 x86_64-w64-mingw32-ar rcs ${openh264_x86_64_DIR}/lib/libopenh264_wrapper.a ${openh264_x86_64_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_64_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_64_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.8
Libs: -L\${prefix}/lib -lopenh264_wrapper
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)

openh264_DIR=${BUILD_DIR}/openh264
if [ ! -d ${openh264_DIR} ]; then
  echo "OpenH264 source tree is not found"
  exit 1
fi
openh264_ARM64_DIR=${openh264_DIR}/install_arm64
# ARM64 OpenH264 wrapper
(
  cd /tmp
  wget https://github.com/mstorsjo/llvm-mingw/releases/download/20251202/llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz
  mkdir -p /app/llvm-mingw
  tar -xf llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz -C /app/llvm-mingw --strip-components=1
  export PATH=/app/llvm-mingw/bin:$PATH
  export CC=aarch64-w64-mingw32-gcc
  export CXX=aarch64-w64-mingw32-g++
  export AR=aarch64-w64-mingw32-ar
  export RANLIB=aarch64-w64-mingw32-ranlib
 cd ${openh264_DIR}
 if [[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]]; then
  make PREFIX=${openh264_ARM64_DIR} install-headers
 else
  PREFIX=${openh264_ARM64_DIR}
  mkdir -p ${PREFIX}/include/wels
  install -m 644 ${openh264_DIR}/codec/api/svc/codec*.h ${PREFIX}/include/wels
 fi
 mkdir -p ${openh264_ARM64_DIR}/lib/pkgconfig
 aarch64-w64-mingw32-gcc -m64 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_ARM64_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_ARM64_DIR}/lib/openh264_wrapper.o
 aarch64-w64-mingw32-ar rcs ${openh264_ARM64_DIR}/lib/libopenh264_wrapper.a ${openh264_ARM64_DIR}/lib/openh264_wrapper.o

 cat >${openh264_ARM64_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_ARM64_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.8
Libs: -L\${prefix}/lib -lopenh264_wrapper
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)

## AOM: https://aomedia.googlesource.com/aom

AOM_X86_DIR=${BUILD_DIR}/aom_x86
AOM_X64_DIR=${BUILD_DIR}/aom_x64
(
  mkdir -p "${AOM_X86_DIR}"
  cd "${AOM_X86_DIR}"
  cmake -GNinja -DAOM_TARGET_CPU=generic -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86-mingw-gcc.cmake -DCMAKE_INSTALL_PREFIX=${AOM_X86_DIR}/install ${AOM_CONFIGURE_OPTIONS} ${AOM_DIR}
  cmake --build . --target install
)
(
  mkdir -p "${AOM_X64_DIR}"
  cd "${AOM_X64_DIR}"
  cmake -GNinja -DAOM_TARGET_CPU=generic \
  -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/x86_64-mingw-gcc.cmake \
  -DCMAKE_INSTALL_PREFIX=${AOM_X64_DIR}/install ${AOM_CONFIGURE_OPTIONS} ${AOM_DIR}
  cmake --build . --target install
)
AOM_DIR=${BUILD_DIR}/aom
if [ ! -d ${AOM_DIR} ]; then
  echo "AOM source tree is not found"
  exit 1
fi
AOM_ARM64_DIR=${BUILD_DIR}/aom_arm64
AOM_CONFIGURE_OPTIONS="-DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TOOLS=OFF -DENABLE_DOCS=OFF -DCONFIG_MULTITHREAD=1 -DCONFIG_AV1_ENCODER=1"
(
  cd /tmp
  wget https://github.com/mstorsjo/llvm-mingw/releases/download/20251202/llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz
  mkdir -p /app/llvm-mingw
  tar -xf llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz -C /app/llvm-mingw --strip-components=1
  export PATH=/app/llvm-mingw/bin:$PATH
  export CC=aarch64-w64-mingw32-gcc
  export CXX=aarch64-w64-mingw32-g++
  export AR=aarch64-w64-mingw32-ar
  export RANLIB=aarch64-w64-mingw32-ranlib
  mkdir -p "${AOM_ARM64_DIR}"
  cd "${AOM_ARM64_DIR}"
  cmake -GNinja -DAOM_TARGET_CPU=generic \
        -DCMAKE_TOOLCHAIN_FILE=${AOM_DIR}/build/cmake/toolchains/arm64-mingw-gcc.cmake \
        -DCMAKE_INSTALL_PREFIX=${AOM_ARM64_DIR}/install ${AOM_CONFIGURE_OPTIONS} ${AOM_DIR}
  cmake --build . --target install
)

FFMPEG_DIR=${BUILD_DIR}/ffmpeg
if [ ! -d ${FFMPEG_DIR} ]; then
  echo "FFMPEG source tree is not found"
  exit 1
fi

## FFmpeg

FFMPEG_x86_DIR=${BUILD_DIR}/ffmpeg_x86
FFMPEG_x86_64_DIR=${BUILD_DIR}/ffmpeg_x86_64
#[ -d ${FFMPEG_x86_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_DIR}
 rsync -a ./ ${FFMPEG_x86_DIR} --exclude .git
 cd ${FFMPEG_x86_DIR}
 PKG_CONFIG_PATH=${openh264_x86_DIR}/lib/pkgconfig:${libvpx_x86_DIR}/install/lib/pkgconfig:${AOM_X86_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86 --target-os=mingw32 --cross-prefix=i686-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
 make -j${CPU_COUNT} install
)
#[ -d ${FFMPEG_x86_64_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_64_DIR}
 rsync -a ./ ${FFMPEG_x86_64_DIR} --exclude .git
 cd ${FFMPEG_x86_64_DIR}
 PKG_CONFIG_PATH=${openh264_x86_64_DIR}/lib/pkgconfig:${libvpx_x64_DIR}/install/lib/pkgconfig:${AOM_X64_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86_64 --target-os=mingw32 --cross-prefix=x86_64-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
 make -j${CPU_COUNT} install
)

FFMPEG_ARM64_DIR=${BUILD_DIR}/ffmpeg_arm64
FFMPEG_CONFIGURE_OPTIONS="--pkg-config=pkg-config --enable-static --enable-avresample --enable-w32threads --enable-libopenh264 --enable-libvpx --disable-filters --disable-bsfs --disable-programs --disable-debug --disable-cuda --disable-cuvid --disable-nvenc --enable-libaom"
#[ -d ${FFMPEG_ARM64_DIR} ] ||
(
  cd /tmp
  wget https://github.com/mstorsjo/llvm-mingw/releases/download/20251202/llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz
  mkdir -p /app/llvm-mingw
  tar -xf llvm-mingw-20251202-ucrt-ubuntu-22.04-aarch64.tar.xz -C /app/llvm-mingw --strip-components=1
  export PATH=/app/llvm-mingw/bin:$PATH
  export CC=aarch64-w64-mingw32-gcc
  export CXX=aarch64-w64-mingw32-g++
  export AR=aarch64-w64-mingw32-ar
  export RANLIB=aarch64-w64-mingw32-ranlib
  cd ${FFMPEG_DIR}
  mkdir -p ${FFMPEG_ARM64_DIR}
  rsync -a ./ ${FFMPEG_ARM64_DIR} --exclude .git
  cd ${FFMPEG_ARM64_DIR}
  find . -type f -exec dos2unix {} \;
  PKG_CONFIG_PATH=${openh264_ARM64_DIR}/lib/pkgconfig:${libvpx_ARM64_DIR}/install/lib/pkgconfig:${AOM_ARM64_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=aarch64 --target-os=mingw32 --cross-prefix=aarch64-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
  make -j${CPU_COUNT} install
)

## OpenCV plugins
./build_videoio_plugin.sh
