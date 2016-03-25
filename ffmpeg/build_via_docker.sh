#!/bin/bash -e
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Build Docker image
docker build -t opencv_ffmpeg_mingw_build docker

echo "Downloading 3rdparty sources..."
./download_src.sh

echo "Running docker container:"
docker run --rm=true -it --name opencv_ffmpeg_mingw_build \
-e "APP_UID=$UID" -e APP_GID=$GROUPS \
-v $(pwd):/app -v $(pwd)/../build:/build -v $(pwd)/../opencv:/build/opencv opencv_ffmpeg_mingw_build
