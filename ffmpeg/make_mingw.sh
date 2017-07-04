#!/bin/bash -ex
# This file is well tested on Ubuntu 14.04
# List of required packages for build see in docker/Dockerfile
# (preferred way is to use Docker to produce similar environment)
#
# This script may not work in MINGW installation on Windows
#
# Usage ${0} <build_dir>
# build directory should be created via download_src.sh script:
#
CURRENT_DIR=`pwd`
BUILD_DIR=${1:-.}
CPU_COUNT=$(nproc || echo 4)

## Libvpx

libvpx_DIR=${BUILD_DIR}/libvpx
libvpx_x86_DIR=${BUILD_DIR}/libvpx_x86
libvpx_x64_DIR=${BUILD_DIR}/libvpx_x64
libvpx_configure_OPTIONS="--disable-examples --disable-unit-tests --disable-install-bins --disable-docs --disable-shared --enable-static --enable-vp8 --enable-vp9 --disable-multithread"
if [ ! -d ${libvpx_DIR} ]; then
  echo "Libvpx source tree is not found"
  exit 1
fi
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

## Open264

openh264_DIR=${BUILD_DIR}/openh264
if [ ! -d ${openh264_DIR} ]; then
  echo "OpenH264 source tree is not found"
  exit 1
fi
openh264_x86_DIR=${openh264_DIR}/install_x86
openh264_x86_64_DIR=${openh264_DIR}/install_x86_64
(
 cd ${openh264_DIR}
 make PREFIX=${openh264_x86_DIR} install-headers
 mkdir -p ${openh264_x86_DIR}/lib/pkgconfig
 i686-w64-mingw32-gcc -m32 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.4
Libs: \${prefix}/lib/openh264_wrapper.o
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)
(
 cd ${openh264_DIR}
 make PREFIX=${openh264_x86_64_DIR} install-headers
 mkdir -p ${openh264_x86_64_DIR}/lib/pkgconfig
 x86_64-w64-mingw32-gcc -m64 -O2 -I${CURRENT_DIR}/openh264_wrapper -I${openh264_x86_64_DIR} \
  -c ${CURRENT_DIR}/openh264_wrapper/wels/openh264_wrapper.c -o ${openh264_x86_64_DIR}/lib/openh264_wrapper.o
 cat >${openh264_x86_64_DIR}/lib/pkgconfig/openh264.pc << EOF
prefix=${openh264_x86_64_DIR}
includedir=\${prefix}/include

Name: OpenH264
Description: OpenH264 wrapper with dynamic loading
Version: 1.4
Libs: \${prefix}/lib/openh264_wrapper.o
Libs.private:
Cflags: -I${CURRENT_DIR}/openh264_wrapper -I\${prefix} -I\${includedir}
EOF
)

FFMPEG_DIR=${BUILD_DIR}/ffmpeg
if [ ! -d ${FFMPEG_DIR} ]; then
  echo "FFMPEG source tree is not found"
  exit 1
fi

## FFmpeg

FFMPEG_x86_DIR=${BUILD_DIR}/ffmpeg_x86
FFMPEG_x86_64_DIR=${BUILD_DIR}/ffmpeg_x86_64
FFMPEG_CONFIGURE_OPTIONS="--pkg-config=pkg-config --enable-static --enable-avresample --enable-w32threads --enable-libopenh264 --enable-libvpx --disable-filters --disable-bsfs --disable-hwaccels --disable-programs --disable-debug --disable-cuda --disable-cuvid --disable-nvenc"
#[ -d ${FFMPEG_x86_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_DIR}
 rsync -a ./ ${FFMPEG_x86_DIR} --exclude .git
 cd ${FFMPEG_x86_DIR}
 PKG_CONFIG_PATH=${openh264_x86_DIR}/lib/pkgconfig:${libvpx_x86_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86 --target-os=mingw32 --cross-prefix=i686-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
 make -j${CPU_COUNT} install
)
#[ -d ${FFMPEG_x86_64_DIR} ] ||
(
 cd ${FFMPEG_DIR}
 mkdir -p ${FFMPEG_x86_64_DIR}
 rsync -a ./ ${FFMPEG_x86_64_DIR} --exclude .git
 cd ${FFMPEG_x86_64_DIR}
 PKG_CONFIG_PATH=${openh264_x86_64_DIR}/lib/pkgconfig:${libvpx_x64_DIR}/install/lib/pkgconfig ./configure --enable-cross-compile --arch=x86_64 --target-os=mingw32 --cross-prefix=x86_64-w64-mingw32- ${FFMPEG_CONFIGURE_OPTIONS} --prefix=`pwd`/install
 make -j${CPU_COUNT} install
)

# Build OpenCV DLL
OPENCV_LOCATION=${BUILD_DIR}/opencv
if [ ! -d ${OPENCV_LOCATION} ]; then
  OPENCV_LOCATION=${CURRENT_DIR}/../..
fi
i686-w64-mingw32-windres -i ${CURRENT_DIR}/opencv_ffmpeg.rc -o ${BUILD_DIR}/opencv_ffmpeg.o
x86_64-w64-mingw32-windres -i ${CURRENT_DIR}/opencv_ffmpeg.rc -o ${BUILD_DIR}/opencv_ffmpeg_64.o
OPENH264WRAPPER_ARGS="-Wl,${openh264_x86_DIR}/lib/openh264_wrapper.o"
i686-w64-mingw32-gcc \
 -m32 -s -Wall -shared -o ${CURRENT_DIR}/opencv_ffmpeg.dll -O2 -x c++ -I${FFMPEG_x86_DIR}/install/include -I${OPENCV_LOCATION}/modules/videoio/src ${CURRENT_DIR}/ffopencv.c -Wl,${BUILD_DIR}/opencv_ffmpeg.o \
 -L${FFMPEG_x86_DIR}/install/lib -L${libvpx_x86_DIR}/install/lib -lavformat -lavcodec -lavdevice -lswscale -lavutil -lvpx -lsecur32 -lws2_32 -lswresample -static -static-libgcc -static-libstdc++ -Wl,-Bstatic \
 ${OPENH264WRAPPER_ARGS} -lstdc++
OPENH264WRAPPER_ARGS="-Wl,${openh264_x86_64_DIR}/lib/openh264_wrapper.o"
x86_64-w64-mingw32-gcc \
 -m64 -s -Wall -shared -o ${CURRENT_DIR}/opencv_ffmpeg_64.dll -O2 -x c++ -I${FFMPEG_x86_64_DIR}/install/include -I${OPENCV_LOCATION}/modules/videoio/src ${CURRENT_DIR}/ffopencv.c -Wl,${BUILD_DIR}/opencv_ffmpeg_64.o \
 -L${FFMPEG_x86_64_DIR}/install/lib -L${libvpx_x64_DIR}/install/lib -lavformat -lavcodec -lavdevice -lswscale -lavutil -lvpx -lsecur32 -lws2_32 -lswresample -static -static-libgcc -static-libstdc++ -Wl,-Bstatic \
 ${OPENH264WRAPPER_ARGS} -lstdc++
