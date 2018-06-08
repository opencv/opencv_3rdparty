#!/bin/bash -e
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Build Docker image
docker build -t opencv_34_ffmpeg_mingw_build_ubuntu1604 docker

echo "Downloading 3rdparty sources..."
[[ "${BUILD_SKIP_DOWNLOAD_SOURCES}" == "" ]] && ./download_src.sh

export | grep -e '-x BUILD_' > ../build/env.sh

echo "Running docker container:"
docker run --rm=true -it --name opencv_34_ffmpeg_mingw_build_ubuntu1604 \
-e "APP_UID=$UID" -e APP_GID=$GROUPS \
-v $(pwd):/app -v $(pwd)/../build:/build -v $(pwd)/../opencv:/build/opencv opencv_34_ffmpeg_mingw_build_ubuntu1604
