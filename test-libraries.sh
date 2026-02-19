#!/bin/bash
set -e

# Script to test the built Lambda layers
# Usage: ./test-libraries.sh

# Check if zip files exist
for layer in base osrm tilemaker osmium; do
    if [[ ! -f "build/aws-lambda-layer-osmtools-$layer.zip" ]]; then
        echo "Error: aws-lambda-layer-osmtools-$layer.zip not found. Please run ./build-libraries.sh first."
        exit 1
    fi
done

echo "Starting library tests using amazonlinux:2023..."

# Create a temporary Dockerfile for testing
cat <<EOF > TestLibraries.dockerfile
FROM --platform=linux/amd64 amazonlinux:2023

# Install Node.js and unzip
RUN yum -y install unzip tar xz
RUN curl -fsSL https://nodejs.org/dist/v22.15.0/node-v22.15.0-linux-x64.tar.xz -o node.tar.xz && \
    tar -xf node.tar.xz --strip-components=1 -C /usr/local && \
    rm node.tar.xz

# Prepare /opt directory (mimicking Lambda environment)
RUN mkdir -p /opt

# Copy layers
COPY build/aws-lambda-layer-osmtools-base.zip /tmp/base.zip
COPY build/aws-lambda-layer-osmtools-osrm.zip /tmp/osrm.zip
COPY build/aws-lambda-layer-osmtools-tilemaker.zip /tmp/tilemaker.zip
COPY build/aws-lambda-layer-osmtools-osmium.zip /tmp/osmium.zip

# Set environment variables for /opt
ENV PATH="/opt/bin:\$PATH"
ENV LD_LIBRARY_PATH="/opt/lib:\$LD_LIBRARY_PATH"
ENV NODE_PATH="/opt/nodejs/node_modules"

WORKDIR /test

# Function to test OSRM layer (needs base)
RUN echo "Testing OSRM layer..." && \
    unzip /tmp/base.zip -d /opt && \
    unzip /tmp/osrm.zip -d /opt && \
    osrm-extract --version && \
    node -e 'const OSRM = require("@project-osrm/osrm"); console.log("OSRM Version:", OSRM.version)' && \
    rm -rf /opt/*

# Function to test Tilemaker layer (needs base)
RUN echo "Testing Tilemaker layer..." && \
    unzip /tmp/base.zip -d /opt && \
    unzip /tmp/tilemaker.zip -d /opt && \
    tilemaker --help && \
    rm -rf /opt/*

# Function to test Osmium layer (needs base)
RUN echo "Testing Osmium layer..." && \
    unzip /tmp/base.zip -d /opt && \
    unzip /tmp/osmium.zip -d /opt && \
    osmium --version && \
    rm -rf /opt/*

# Final check: all together
RUN echo "Testing all layers together..." && \
    unzip -o /tmp/base.zip -d /opt && \
    unzip -o /tmp/osrm.zip -d /opt && \
    unzip -o /tmp/tilemaker.zip -d /opt && \
    unzip -o /tmp/osmium.zip -d /opt && \
    osrm-extract --version && \
    osmium --version && \
    tilemaker --help && \
    node -e 'const OSRM = require("@project-osrm/osrm"); console.log("OSRM Version:", OSRM.version)'

CMD ["echo", "All tests passed!"]
EOF

# Build and run the test container
docker build -f TestLibraries.dockerfile -t lambda-layer-test .
docker run --rm lambda-layer-test

# Cleanup
rm TestLibraries.dockerfile
echo "Tests completed successfully."
