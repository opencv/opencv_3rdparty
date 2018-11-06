#!/bin/bash -e
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Build Docker image
docker build -t opencv_ffmpeg_mingw_build_ubuntu1804 docker

echo "Downloading 3rdparty sources..."
if [[ ! "${BUILD_SKIP_DOWNLOAD_SOURCES}" ]]; then
  ./download_src.sh
fi

echo "Capture/exporting BUILD_* vars..."
export | (grep -e '-x BUILD_' || true) > ../build/env.sh

echo "Running docker container:"
docker run --rm=true -it --name opencv_ffmpeg_mingw_build_ubuntu1804 \
-e "APP_UID=$UID" -e APP_GID=$GROUPS \
-v $(pwd):/app -v $(pwd)/../build:/build -v $(pwd)/../opencv:/build/opencv opencv_ffmpeg_mingw_build_ubuntu1804
