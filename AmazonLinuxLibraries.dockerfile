FROM --platform=linux/amd64 amazonlinux:2023

ARG NODE_VERSION="22.15.0"
ARG OSRM_VERSION="6.0.0"
ARG TILEMAKER_VERSION="3.0.0"
ARG MAPNIK_VERSION="4.1.3"

RUN yum -y install libxml2-devel bzip2-devel boost-devel libzip-devel \
      lua.x86_64 lua-devel.x86_64 luajit.x86_64 luajit-devel.x86_64 \
      expat expat-devel sqlite-devel libatomic bzip2 diffutils binutils \
      gcc14 gcc14-c++ cmake unzip wget tar xz gzip

WORKDIR /home

RUN wget "https://github.com/uxlfoundation/oneTBB/releases/download/v2022.1.0/oneapi-tbb-2022.1.0-lin.tgz" -O onetbb.tgz
RUN tar -xf onetbb.tgz && \
    cp -a oneapi-tbb-2022.1.0/lib/intel64/gcc4.8/. /usr/local/lib/ && \
    cp -a oneapi-tbb-2022.1.0/include/. /usr/local/include/

RUN wget "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -O node.tgz
RUN tar -xf node.tgz && \
    ls node-v${NODE_VERSION}-linux-x64 && \
    cp -a node-v${NODE_VERSION}-linux-x64/bin/. /usr/local/bin && \
    cp -a node-v${NODE_VERSION}-linux-x64/include/. /usr/local/include && \
    cp -a node-v${NODE_VERSION}-linux-x64/lib/. /usr/local/lib && \
    cp -a node-v${NODE_VERSION}-linux-x64/share/. /usr/local/share && \
    export PATH="$PATH:/usr/local/bin" && \
    node -v

RUN wget "https://github.com/Project-OSRM/osrm-backend/archive/refs/tags/v${OSRM_VERSION}.tar.gz" -O osrm.tgz
RUN tar -xf osrm.tgz && \
    cd osrm-backend-${OSRM_VERSION} && \
    npm install --ignore-scripts && \
    sed -i -e 's/LUA_COMPAT_5_2/LUA_COMPAT_5_2 1/g' /usr/include/luaconf-x86_64.h && \
    sed -i '1s/^/#include <utility>\n/' /usr/include/boost/asio/awaitable.hpp && \
    sed -i -e 's/Boost REQUIRED CONFIG COMPONENTS/Boost REQUIRED COMPONENTS/g' CMakeLists.txt && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ CC=gcc14-cc cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_NODE_BINDINGS=On -DCMAKE_CXX_FLAGS="-Wno-error=uninitialized" && \
    cmake --build . -j4 

RUN wget "https://github.com/osmcode/osmium-tool/archive/refs/tags/v1.18.0.tar.gz" -O osmium.tgz
RUN wget "https://github.com/osmcode/libosmium/archive/refs/tags/v2.22.0.tar.gz" -O libosmium.tgz
RUN wget "https://github.com/mapbox/protozero/archive/refs/tags/v1.8.0.tar.gz" -O protozero.tgz
RUN yum install -y lz4-devel
RUN tar -xf protozero.tgz && \
    cd protozero-1.8.0 && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ cmake .. -DBUILD_TESTING=OFF && \
    make && \
    make install
RUN tar -xf libosmium.tgz && \
    cd libosmium-2.22.0 && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ cmake .. -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF && \
    make && \
    make install
RUN wget "https://github.com/nlohmann/json/archive/refs/tags/v3.12.0.tar.gz" -O nlohmann_json.tgz
RUN tar -xf nlohmann_json.tgz && \
    cd json-3.12.0 && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ cmake .. -DJSON_BuildTests=OFF && \
    make && \
    make install
RUN tar -xf osmium.tgz && \
    cd osmium-tool-1.18.0 && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ cmake .. -DBUILD_TESTING=OFF && \
    cmake --build .

RUN wget "https://github.com/OSGeo/shapelib/releases/download/v1.6.1/shapelib-1.6.1.tar.gz" -O shapelib.tgz
RUN wget "https://github.com/systemed/tilemaker/archive/refs/tags/v${TILEMAKER_VERSION}.tar.gz" -O tilemaker.tgz
RUN tar -xf shapelib.tgz && \
    cd shapelib-1.6.1 && \
    CXX=gcc14-g++ ./configure && \
    make && \
    make install
RUN wget "https://github.com/Tencent/rapidjson/archive/refs/heads/master.zip" -O rapidjson.zip
RUN unzip rapidjson.zip && \
    cd rapidjson-master && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ CC=gcc14-cc cmake .. -DRAPIDJSON_BUILD_DOC=OFF -DRAPIDJSON_BUILD_EXAMPLES=OFF -DRAPIDJSON_BUILD_TESTS=OFF && \
    cmake --build . && \
    cmake --install .
RUN tar -xf tilemaker.tgz && \
    cd tilemaker-${TILEMAKER_VERSION} && \
    mkdir build && \
    cd build && \
    CXX=gcc14-g++ CC=gcc14-cc cmake .. && \
    cmake --build .

RUN cd osrm-backend-${OSRM_VERSION} && \
    mkdir -p /home/export/node_modules/@project-osrm/osrm/lib && \
    cp package.json /home/export/node_modules/@project-osrm/osrm/ && \
    cp package-lock.json /home/export/node_modules/@project-osrm/osrm/ && \
    cp lib/index.js /home/export/node_modules/@project-osrm/osrm/lib/index.js && \
    cp -r lib/binding /home/export/node_modules/@project-osrm/osrm/lib && \
    mkdir /home/export/lib && \
    cp /usr/lib64/libboost_regex.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_date_time.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_chrono.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_filesystem.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_iostreams.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_thread.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_system.so.1.75.0 /home/export/lib/ && \
    cp /usr/lib64/libboost_program_options.so.1.75.0 /home/export/lib/ && \
    cp /usr/local/lib/libtbb.so.12 /home/export/lib/ && \
    cp /usr/lib64/libicudata.so.67 /home/export/lib/ && \
    cp /usr/lib64/libicui18n.so.67 /home/export/lib/ && \
    cp /usr/lib64/libicuuc.so.67 /home/export/lib/ && \
    cd ../osmium-tool-1.18.0 && \
    mkdir /home/export/bin && \
    cp build/src/osmium /home/export/bin/osmium && \
    cp /usr/lib64/libexpat.so.1 /home/export/lib/ && \
    cd ../tilemaker-${TILEMAKER_VERSION} && \
    cp /usr/local/lib/libshp.so.4 /home/export/lib/ && \
    cp /usr/lib64/libatomic.so.1 /home/export/lib/ && \
    cp build/tilemaker /home/export/bin/tilemaker && \
    cd /home/export && \
    zip -r /home/osrm-prebuilt-amazonlinux2023.zip .
