#!/usr/bin/env bash
set -euo pipefail

# installing a header-only CUDA tree for clangd on machines without a toolkit

CUDA_RELEASE="12.8.2"
CUDA_TOOLKIT_VERSION="12.8.93"
CUDA_SDK_VERSION="12.8"
CUDA_DIR="${CUDA_DIR:-$HOME/.local/cuda}"
BASE_URL="https://developer.download.nvidia.com/compute/cuda/redist"

# versions and checksums come from NVIDIA's CUDA 12.8.2 redistribution manifest
CCCL_VERSION="12.8.90"
CUDART_VERSION="12.8.90"
NVCC_VERSION="12.8.93"
CURAND_VERSION="10.3.9.90"

HOST_OS=$(uname -s)
HOST_ARCH=$(uname -m)

case "$HOST_OS" in
    Darwin | Linux) ;;
    *)
        echo "Unsupported operating system: $HOST_OS" >&2
        exit 1
        ;;
esac

# using NVIDIA's Linux archives because it does not publish macOS CUDA packages;
# only their platform-independent headers are copied into the local tree
case "$HOST_ARCH" in
    x86_64 | amd64)
        REDIST_PLATFORM="linux-x86_64"
        CCCL_SHA256="0740e9e01e4f15e17c5ab8d68bba4f8ec0eb6b84edccba4ac45112d2d2174e4b"
        CUDART_SHA256="8d566b5fe745c46842dc16945cf36686227536decd2302c372be86da37faca68"
        NVCC_SHA256="9961b3484b6b71314063709a4f9529654f96782ad39e72bf1e00f070db8210d3"
        CURAND_SHA256="32a5ec30be446c1b7228d1bc502b2f029cc8b59a5e362c70d960754fa646778b"
        ;;
    arm64 | aarch64)
        REDIST_PLATFORM="linux-aarch64"
        CCCL_SHA256="d2c88dd447a7dcbc8eb1d416c34d88e9df03745dc471b6cfaf93f5ef161d5dbd"
        CUDART_SHA256="0cdde0058d47b3307bc2d58156cfadce092631a3d24616e1b88d6ef089b5ca73"
        NVCC_SHA256="2eb267e6ebbe17e5ebc593bae8b83fa927c3e53cbf43ef5c614eff6c94053d10"
        CURAND_SHA256="bd2ff4a5ef69f37e943d20fb5017c7f6d789b6f78da6365fab5021e500e6305a"
        ;;
    *)
        echo "Unsupported architecture: $HOST_ARCH" >&2
        exit 1
        ;;
esac

installation_complete() {
    [ -f "$CUDA_DIR/version.txt" ] &&
        grep -Fxq "CUDA Version $CUDA_TOOLKIT_VERSION" "$CUDA_DIR/version.txt" &&
        [ -f "$CUDA_DIR/include/cuda_runtime.h" ] &&
        [ -f "$CUDA_DIR/include/crt/host_runtime.h" ] &&
        [ -f "$CUDA_DIR/include/nv/target" ] &&
        [ -f "$CUDA_DIR/include/curand_mtgp32_kernel.h" ]
}

print_clangd_config() {
    echo ""
    echo "Add this to the project's .clangd file:"
    echo "CompileFlags:"
    echo "  Add:"
    echo "    ["
    echo "      --cuda-host-only,"
    echo "      --cuda-path=$CUDA_DIR,"
    echo "      --cuda-gpu-arch=sm_75,"
    if [ "$HOST_OS" = "Darwin" ]; then
        echo "      -Xclang,"
        echo "      -target-sdk-version=$CUDA_SDK_VERSION,"
    fi
    echo "    ]"

    if [ "$HOST_OS" = "Darwin" ]; then
        echo ""
        echo "macOS also needs a CUDA-capable clangd, such as Homebrew LLVM:"
        echo "  brew install llvm"
        if command -v brew >/dev/null 2>&1; then
            echo "  clangd path: $(brew --prefix llvm)/bin/clangd"
        fi
    fi
}

if installation_complete; then
    echo "CUDA $CUDA_RELEASE headers are already installed at $CUDA_DIR"
    print_clangd_config
    exit 0
fi

for command_name in curl tar mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

if command -v shasum >/dev/null 2>&1; then
    SHA256_COMMAND="shasum"
elif command -v sha256sum >/dev/null 2>&1; then
    SHA256_COMMAND="sha256sum"
else
    echo "Required checksum command not found: install sha256sum or shasum" >&2
    exit 1
fi

mkdir -p "$(dirname "$CUDA_DIR")"
STAGE_DIR=$(mktemp -d "${CUDA_DIR}.tmp.XXXXXX")
DOWNLOAD_DIR="$STAGE_DIR/downloads"
mkdir -p "$DOWNLOAD_DIR" "$STAGE_DIR/bin" "$STAGE_DIR/include" \
    "$STAGE_DIR/lib64" "$STAGE_DIR/nvvm/libdevice"

cleanup() {
    if [ -n "${STAGE_DIR:-}" ] && [ -d "$STAGE_DIR" ]; then
        rm -rf "$STAGE_DIR"
    fi
}
trap cleanup EXIT

verify_sha256() {
    local archive=$1
    local expected=$2

    if [ "$SHA256_COMMAND" = "sha256sum" ]; then
        printf '%s  %s\n' "$expected" "$archive" | sha256sum -c - >/dev/null
    else
        printf '%s  %s\n' "$expected" "$archive" | shasum -a 256 -c >/dev/null
    fi
}

install_component() {
    local component=$1
    local version=$2
    local expected_sha256=$3
    local archive="${component}-${REDIST_PLATFORM}-${version}-archive.tar.xz"
    local archive_path="$DOWNLOAD_DIR/$archive"
    local extract_dir="$DOWNLOAD_DIR/${archive%.tar.xz}"

    echo "Downloading $component $version..."
    curl --fail --location --retry 3 --output "$archive_path" \
        "$BASE_URL/$component/$REDIST_PLATFORM/$archive"
    verify_sha256 "$archive_path" "$expected_sha256"
    tar -xf "$archive_path" -C "$DOWNLOAD_DIR"

    if [ ! -d "$extract_dir/include" ]; then
        echo "$component archive does not contain an include directory" >&2
        exit 1
    fi

    cp -R "$extract_dir/include/." "$STAGE_DIR/include/"
}

echo "Installing CUDA $CUDA_RELEASE headers for $HOST_OS/$HOST_ARCH..."
install_component cuda_cccl "$CCCL_VERSION" "$CCCL_SHA256"
install_component cuda_cudart "$CUDART_VERSION" "$CUDART_SHA256"
install_component cuda_nvcc "$NVCC_VERSION" "$NVCC_SHA256"
install_component libcurand "$CURAND_VERSION" "$CURAND_SHA256"

printf 'CUDA Version %s\n' "$CUDA_TOOLKIT_VERSION" > "$STAGE_DIR/version.txt"
touch "$STAGE_DIR/nvvm/libdevice/libdevice.10.bc"
printf '%s\n' \
    "CUDA release: $CUDA_RELEASE" \
    "Platform archive: $REDIST_PLATFORM" \
    "Components: cuda_cccl=$CCCL_VERSION cuda_cudart=$CUDART_VERSION cuda_nvcc=$NVCC_VERSION libcurand=$CURAND_VERSION" \
    > "$STAGE_DIR/header-only-install.txt"
rm -rf "$DOWNLOAD_DIR"

if [ -e "$CUDA_DIR" ] || [ -L "$CUDA_DIR" ]; then
    BACKUP_DIR="${CUDA_DIR}.backup-$(date +%Y%m%d%H%M%S)"
    mv "$CUDA_DIR" "$BACKUP_DIR"
    echo "Previous CUDA header tree moved to $BACKUP_DIR"
fi

mv "$STAGE_DIR" "$CUDA_DIR"
STAGE_DIR=""

echo "CUDA $CUDA_RELEASE headers installed at $CUDA_DIR"
print_clangd_config
