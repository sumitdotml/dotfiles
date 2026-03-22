#!/bin/bash
set -e

# Sets up CUDA headers for clangd LSP support on machines without CUDA installed.
# This downloads header files only -- no GPU or CUDA toolkit required.
# After running this, clangd can resolve cudaMalloc, __global__, threadIdx, etc.
#
# Requires: brew install llvm (for a clangd with CUDA support)
# Per-project: add a .clangd file with:
#   CompileFlags:
#     Add: [--cuda-host-only, --cuda-path=$HOME/.local/cuda, --cuda-gpu-arch=sm_75]

CUDA_VERSION="12.6.77"
CUDA_DIR="$HOME/.local/cuda"
BASE_URL="https://developer.download.nvidia.com/compute/cuda/redist"

if [ -d "$CUDA_DIR/include/crt" ]; then
    echo "CUDA headers already installed at $CUDA_DIR"
    exit 0
fi

echo "Setting up CUDA headers for LSP support..."

# clang validates cuda-path by checking for bin/, lib64/, nvvm/libdevice/, and version.txt
mkdir -p "$CUDA_DIR/bin" "$CUDA_DIR/lib64" "$CUDA_DIR/nvvm/libdevice" "$CUDA_DIR/include"
echo "CUDA Version $CUDA_VERSION" > "$CUDA_DIR/version.txt"
touch "$CUDA_DIR/nvvm/libdevice/libdevice.10.bc"

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "Downloading cuda_cudart headers..."
curl -LO "$BASE_URL/cuda_cudart/linux-x86_64/cuda_cudart-linux-x86_64-${CUDA_VERSION}-archive.tar.xz"
tar xf "cuda_cudart-linux-x86_64-${CUDA_VERSION}-archive.tar.xz"
cp -r "cuda_cudart-linux-x86_64-${CUDA_VERSION}-archive/include/"* "$CUDA_DIR/include/"

echo "Downloading cuda_nvcc headers..."
curl -LO "$BASE_URL/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-${CUDA_VERSION}-archive.tar.xz"
tar xf "cuda_nvcc-linux-x86_64-${CUDA_VERSION}-archive.tar.xz"
cp -r "cuda_nvcc-linux-x86_64-${CUDA_VERSION}-archive/include/"* "$CUDA_DIR/include/"

cd -
rm -rf "$TMPDIR"

echo "CUDA headers installed at $CUDA_DIR"
echo ""
echo "Next steps:"
echo "  1. brew install llvm  (if not already installed)"
echo "  2. Add a .clangd file to your CUDA project with:"
echo "     CompileFlags:"
echo "       Add: [--cuda-host-only, --cuda-path=$CUDA_DIR, --cuda-gpu-arch=sm_75]"
