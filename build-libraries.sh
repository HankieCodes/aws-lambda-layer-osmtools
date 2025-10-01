#/usr/bin/env bash
set -e

docker build -f ./AmazonLinuxLibraries.dockerfile -t skyway-amz-libraries:latest .
docker run --rm --platform linux/amd64 -v .:/home/host skyway-amz-libraries:latest cp osrm-prebuilt-amazonlinux2023.zip host/
