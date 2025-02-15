#!/usr/bin/env bash

set -e
set -o pipefail

ARGON_JS_EXTRA_C_FLAGS=""
if [[ "$ARGON_JS_BUILD_BUILD_WITH_SIMD" == "1" ]]; then
    ARGON_JS_EXTRA_C_FLAGS="-msimd128 -msse2"
fi

ARGON_THREADS_EXTRA_EXE_LINKER_FLAGS=""
ARGON_THREADS_EXTRA_C_FLAGS=""
if [[ "$ARGON_JS_BUILD_BUILD_WITH_THREADS" == "1" ]]; then
    ARGON_THREADS_EXTRA_EXE_LINKER_FLAGS="-s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=16 -s ALLOW_BLOCKING_ON_MAIN_THREAD=1"
else
    ARGON_THREADS_EXTRA_C_FLAGS="-DARGON2_NO_THREADS"
fi

cmake \
    -DOUTPUT_NAME="argon2" \
    -DCMAKE_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake \
    -DCMAKE_VERBOSE_MAKEFILE=OFF \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_C_FLAGS="-O3 $ARGON_JS_EXTRA_C_FLAGS $ARGON_THREADS_EXTRA_C_FLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="-O3 --memory-init-file 0 \
                              -s NO_FILESYSTEM=1 \
                              -s 'EXPORTED_FUNCTIONS=[\"_argon2_hash\",\"_argon2_hash_ext\",\"_argon2_verify\",\"_argon2_verify_ext\",\"_argon2_error_message\",\"_argon2_encodedlen\",\"_malloc\",\"_free\"]' \
                              -s 'EXPORTED_RUNTIME_METHODS=[\"UTF8ToString\",\"allocate\",\"ALLOC_NORMAL\"]' \
                              -s DEMANGLE_SUPPORT=0 \
                              -s ASSERTIONS=0 \
                              -s NO_EXIT_RUNTIME=1 \
                              -s TOTAL_MEMORY=16MB \
                              -s BINARYEN_MEM_MAX=2147418112 \
                              -s ALLOW_MEMORY_GROWTH=1 \
                              -s WASM=1 \
                              $ARGON_THREADS_EXTRA_EXE_LINKER_FLAGS" \
    .
cmake --build .

shasum dist/argon2.js
shasum dist/argon2.wasm
shasum dist/argon2.worker.js

perl -pi -e 's/"argon2.js.mem"/null/g' dist/argon2.js
perl -pi -e 's/$/if(typeof module!=="undefined")module.exports=Module;Module.unloadRuntime=function(){if(typeof self!=="undefined"){delete self.Module}Module=jsModule=wasmMemory=wasmTable=asm=buffer=HEAP8=HEAPU8=HEAP16=HEAPU16=HEAP32=HEAPU32=HEAPF32=HEAPF64=undefined;if(typeof module!=="undefined"){delete module.exports}};/' dist/argon2.js
perl -pi -e 's/typeof Module!="undefined"\?Module:\{};/typeof self!=="undefined"&&typeof self.Module!=="undefined"?self.Module:{};var jsModule=Module;/g' dist/argon2.js
perl -pi -e 's/receiveInstantiatedSource\(output\)\{/receiveInstantiatedSource(output){Module=jsModule;if(typeof self!=="undefined")self.Module=Module;/g' dist/argon2.js
perl -pi -e 's/else if(ENVIRONMENT_IS_NODE){_scriptDir=__filename}/else if(ENVIRONMENT_IS_NODE){_scriptDir=__filename}else{_scriptDir="app/argon2-threads.js"}/g' dist/argon2.js