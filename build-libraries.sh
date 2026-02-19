#/usr/bin/env bash
set -e

mkdir -p build

docker build -f ./AmazonLinuxLibraries.dockerfile -t amz-built-osmtools:latest .
docker run --rm --platform linux/amd64 -v .:/home/host amz-built-osmtools:latest sh -c \
  "cp aws-lambda-layer-osmtools-base.zip host/build && \
   cp aws-lambda-layer-osmtools-osrm.zip host/build && \
   cp aws-lambda-layer-osmtools-tilemaker.zip host/build && \
   cp aws-lambda-layer-osmtools-osmium.zip host/build"
