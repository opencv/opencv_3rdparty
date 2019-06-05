#!/bin/bash -e
# TODO: reduce binaries size
# - gc-sections doesn't work properly with MinGW: https://sourceware.org/bugzilla/show_bug.cgi?id=11539

{ # force bash to read file completelly

. ../build/env.sh

CURRENT_DIR=`pwd`
BUILD_DIR=${1:-/build}
CPU_COUNT=$(nproc || echo 4)

DST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OPENCV_CMAKE_ARGS=(
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_SHARED_LIBS=OFF
  -DCPU_DISPATCH=
  -DOPENCV_EXTRA_FLAGS="-DCV_EXPORTS= -D_GNU_SOURCE="
  -DWITH_IPP=OFF -DWITH_ADE=OFF -DWITH_LAPACK=OFF -DWITH_OPENCL=OFF -DWITH_DIRECTX=OFF -DWITH_WIN32UI=OFF
  -DWITH_EIGEN=OFF -DWITH_JPEG=OFF -DWITH_WEBP=OFF -DWITH_JASPER=OFF -DWITH_OPENEXR=OFF -DWITH_PNG=OFF -DWITH_TIFF=OFF
  -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DWITH_DSHOW=OFF -DWITH_1394=OFF
  -DWITH_PROTOBUF=OFF -DWITH_IMGCODEC_HDR=OFF -DWITH_IMGCODEC_SUNRASTER=OFF -DWITH_IMGCODEC_PXM=OFF -DWITH_IMGCODEC_PFM=OFF
  -DWITH_ITT=OFF -DCV_TRACE=OFF
  -DBUILD_LIST=core,imgproc,videoio
)

OPENCV_PLUGIN_CMAKE_ARGS=(
  "-DCMAKE_MODULE_LINKER_FLAGS=-static -lbcrypt -static-libgcc -static-libstdc++ -Wl,--gc-sections -Wl,-Bsymbolic"
  -DCMAKE_BUILD_TYPE=Release
  -DOPENCV_PLUGIN_MODULE_PREFIX=
  -DOPENCV_FFMPEG_SKIP_DOWNLOAD=ON
  -DCMAKE_INSTALL_PREFIX=$DST_DIR
  ${BUILD_DIR}/opencv/modules/videoio/misc/plugin_ffmpeg
  "-DOPENCV_PLUGIN_EXTRA_SRC_FILES=$DST_DIR/opencv_ffmpeg.rc"
)

build_opencv_64()
{
(
  [[ -n "${CLEAN_BUILD_DIR}" ]] && {
    rm -rf ${BUILD_DIR}/opencv_x86_64
  }
  mkdir -p ${BUILD_DIR}/opencv_x86_64
  pushd ${BUILD_DIR}/opencv_x86_64
  set -e
  set -x
  cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=$CURRENT_DIR/mingw-toolchain-x86_64.cmake \
      "${OPENCV_CMAKE_ARGS[@]}" \
      /build/opencv
  ninja opencv_modules -j${CPU_COUNT}
  popd
)
}

build_plugin_64()
{
(
  rm -rf ${BUILD_DIR}/opencv_ffmpeg_plugin_x86_64
  mkdir -p ${BUILD_DIR}/opencv_ffmpeg_plugin_x86_64
  pushd ${BUILD_DIR}/opencv_ffmpeg_plugin_x86_64

  set -e
  set -x
  PKG_CONFIG_PATH=${BUILD_DIR}/ffmpeg_x86_64/install/lib/pkgconfig \
  RCFLAGS=-DFFMPEG_INTERNAL_NAME=opencv_videoio_ffmpeg_64 \
  cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=$CURRENT_DIR/mingw-toolchain-x86_64.cmake \
      -DOpenCV_DIR=${BUILD_DIR}/opencv_x86_64 \
      -DOPENCV_PLUGIN_NAME=opencv_videoio_ffmpeg_64 \
      ${OPENCV_PLUGIN_CMAKE_ARGS[@]}
  ninja -v
  ninja install/strip
  popd
)
}

build_opencv_32()
{
(
  [[ -n "${CLEAN_BUILD_DIR}" ]] && {
    rm -rf ${BUILD_DIR}/opencv_x86
  }
  mkdir -p ${BUILD_DIR}/opencv_x86
  pushd ${BUILD_DIR}/opencv_x86

  set -e
  set -x
  cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=$CURRENT_DIR/mingw-toolchain-i686.cmake \
      "${OPENCV_CMAKE_ARGS[@]}" \
      /build/opencv
  ninja opencv_modules -j${CPU_COUNT}
  popd
)
}

build_plugin_32()
{
(
  rm -rf ${BUILD_DIR}/opencv_ffmpeg_plugin_x86
  mkdir -p ${BUILD_DIR}/opencv_ffmpeg_plugin_x86
  pushd ${BUILD_DIR}/opencv_ffmpeg_plugin_x86

  set -e
  set -x
  PKG_CONFIG_PATH=${BUILD_DIR}/ffmpeg_x86/install/lib/pkgconfig \
  RCFLAGS=-DFFMPEG_INTERNAL_NAME=opencv_videoio_ffmpeg \
  cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=$CURRENT_DIR/mingw-toolchain-i686.cmake \
      -DOpenCV_DIR=${BUILD_DIR}/opencv_x86 \
      -DOPENCV_PLUGIN_NAME=opencv_videoio_ffmpeg \
      ${OPENCV_PLUGIN_CMAKE_ARGS[@]}
  ninja -v
  ninja install/strip
  popd
)
}

DEFAULT_TASKS=${1:-build_opencv_64 build_plugin_64 build_opencv_32 build_plugin_32}
for t in $DEFAULT_TASKS $@; do
  echo "Task: $t"
  $t
done

exit 0
}
