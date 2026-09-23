#!/bin/bash
set -euo pipefail
mkdir -p ~/models
if [ ! -d ~/llama.cpp-src ]; then
    git clone https://github.com/ggerganov/llama.cpp ~/llama.cpp-src
else
    git -C ~/llama.cpp-src pull
fi
cmake -S ~/llama.cpp-src -B ~/llama.cpp-src/build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build ~/llama.cpp-src/build --config Release -j"$(nproc)"
