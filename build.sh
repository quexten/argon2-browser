#!/usr/bin/env bash

set -e
set -o pipefail

rm -rf dist
mkdir dist
rm -rf docs/dist
mkdir docs/dist

./clean-cmake.sh
ARGON_JS_BUILD_BUILD_WITH_SIMD=1 ARGON_JS_BUILD_BUILD_WITH_THREADS=1 ./build-wasm.sh
cp dist/argon2.js docs/dist/argon2-threads.js
cp dist/argon2.wasm docs/dist/argon2-simd-threads.wasm
cp dist/argon2.worker.js docs/dist/argon2.worker.js

./clean-cmake.sh
ARGON_JS_BUILD_BUILD_WITH_SIMD=0 ARGON_JS_BUILD_BUILD_WITH_THREADS=1 ./build-wasm.sh
cp dist/argon2.wasm docs/dist/argon2-threads.wasm
mv dist/argon2.wasm dist/argon2-threads.wasm

./clean-cmake.sh
ARGON_JS_BUILD_BUILD_WITH_SIMD=1 ARGON_JS_BUILD_BUILD_WITH_THREADS=0 ./build-wasm.sh
cp dist/argon2.js docs/dist/argon2.js
cp dist/argon2.wasm docs/dist/argon2-simd.wasm
mv dist/argon2.wasm dist/argon2-simd.wasm

./clean-cmake.sh
ARGON_JS_BUILD_BUILD_WITH_SIMD=0 ARGON_JS_BUILD_BUILD_WITH_THREADS=0 ./build-wasm.sh
cp dist/argon2.wasm docs/dist/argon2.wasm

./clean-cmake.sh

echo Done
