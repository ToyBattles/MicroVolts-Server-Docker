FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-pip \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y gcc-13 g++-13 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the MicrovoltsEmulator repository
RUN git clone https://github.com/SoWeBegin/MicrovoltsEmulator .

# Clone and setup vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git ExternalLibraries/vcpkg \
    && ./ExternalLibraries/vcpkg/bootstrap-vcpkg.sh

RUN ./ExternalLibraries/vcpkg/vcpkg install --triplet=x64-linux

RUN cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=ExternalLibraries/vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libssl3 \
    libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/build/AuthServer/AuthServer.elf /app/Output/
COPY --from=builder /app/build/MainServer/MainServer.elf /app/Output/
COPY --from=builder /app/build/CastServer/CastServer.elf /app/Output/

COPY Setup/ /app/Setup/
COPY microvolts-db.sql /app/

RUN mkdir -p /app/Output

ENV MV_DB_PW=default_password

EXPOSE 13000 13005 13006

CMD ["/bin/bash"]