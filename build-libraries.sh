#/usr/bin/env bash
set -e

docker build -f ./AmazonLinuxLibraries.dockerfile -t amz-built-osmtools:latest .
docker run --rm --platform linux/amd64 -v .:/home/host amz-built-osmtools:latest cp aws-lambda-layer-osmtools.zip host/
