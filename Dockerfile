FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    ca-certificates \
    zip \
    unzip \
    tar \
    python3 \
    python3-pip \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 22.04 ships CMake 3.22.x, but the emulator requires CMake >= 3.26.
# Install a newer CMake via pip (places `cmake` in /usr/local/bin).
RUN python3 -m pip install --no-cache-dir "cmake>=3.26" \
    && cmake --version

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
    # Build all 3 server targets explicitly (default target may not build all)
    && cmake --build build --config Release --target AuthServer MainServer CastServer \
    # Normalize build artifacts into a stable path for the runtime stage
    && mkdir -p /app/Output \
    # Some upstream builds output to /app/*.elf (not under build/), so search both.
    && find /app -maxdepth 3 -type f -name '*.elf' -exec cp -f {} /app/Output/ \; \
    # Fail early if expected server binaries were not produced
    && test -f /app/Output/AuthServer.elf \
    && test -f /app/Output/MainServer.elf \
    && test -f /app/Output/CastServer.elf

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libssl3 \
    libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/Output/ /app/Output/

COPY --from=builder /app/Setup/ /app/Setup/
COPY --from=builder /app/microvolts-db.sql /app/

# Runtime entrypoint patches config.ini based on environment variables.
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

RUN mkdir -p /app/Output

ENV MV_DB_PW=default_password

EXPOSE 13000 13005 13006

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/bin/bash"]
