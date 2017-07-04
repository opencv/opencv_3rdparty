#!/bin/bash
DIR=./build/ffmpeg
[ -d $DIR ] || DIR=../build/ffmpeg
find $DIR -name '*version*.h' -exec grep -n -A3 'VERSION_MAJOR  ' {} \;
