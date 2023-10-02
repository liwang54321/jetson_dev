# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(target_arch aarch64-linux-gnu)
set(CMAKE_LIBRARY_ARCHITECTURE ${target_arch} CACHE STRING "" FORCE)

set(rootfs_path ${CMAKE_CURRENT_SOURCE_DIR}/../Linux_for_Tegra/rootfs_dev)

# Configure cmake to look for libraries, include directories and
# packages inside the target root prefix.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_FIND_ROOT_PATH  ${rootfs_path})
include_directories(BEFORE SYSTEM ${rootfs_path}/usr/include)

# setup compiler for cross-compilation
set(CMAKE_CXX_FLAGS           "-fPIC"               CACHE STRING "c++ flags")
set(CMAKE_C_FLAGS             "-fPIC"               CACHE STRING "c flags")
set(CMAKE_SHARED_LINKER_FLAGS ""                    CACHE STRING "shared linker flags")
set(CMAKE_MODULE_LINKER_FLAGS ""                    CACHE STRING "module linker flags")
set(CMAKE_EXE_LINKER_FLAGS    ""                    CACHE STRING "executable linker flags")

# needed to avoid doing some more strict compiler checks that
# are failing when cross-compiling
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# specify the toolchain programs
set(CMAKE_C_COMPILER ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/bin/aarch64-buildroot-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/bin/aarch64-buildroot-linux-gnu-g++)
set(CMAKE_AR ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/bin/aarch64-buildroot-linux-gnu-ar)
set(CMAKE_RANLIB ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/bin/aarch64-buildroot-linux-gnu-ranlib)
set(CMAKE_LINKER ${CMAKE_CURRENT_SOURCE_DIR}/../toolchain/bin/aarch64-buildroot-linux-gnu-ld)


# Not all shared libraries dependencies are instaled in host machine.
# Make sure linker doesn't complain.
set(CMAKE_EXE_LINKER_FLAGS_INIT -Wl,--allow-shlib-undefined)

# For Cuda
if (DEFINED CUDA_DIR)
    if((DEFINED CUDA_TOOLKIT_ROOT_DIR) AND (NOT CUDA_TOOLKIT_ROOT_DIR STREQUAL CUDA_DIR))
        message(FATAL_ERROR "Cannot set both CUDA_DIR and (legacy) CUDA_TOOLKIT_ROOT_DIR")
    endif()
elseif (DEFINED ENV{CUDA_INSTALL_DIR})
    set(CUDA_DIR $ENV{CUDA_INSTALL_DIR})
else()
    set(CUDA_DIR  "/usr/local/cuda/" CACHE PATH "CUDA Toolkit location.")
endif()

if(NOT CMAKE_CUDA_COMPILER)
    set(CMAKE_CUDA_COMPILER ${CUDA_DIR}/bin/nvcc)
endif()

set(CMAKE_CUDA_HOST_LINK_LAUNCHER       ${CUDA_DIR}/bin/nvcc)
set(CUDA_LIBRARY_DIRS                   ${CUDA_DIR}/targets/aarch64-linux/lib)
set(CMAKE_EXE_LINKER_FLAGS              "-L${CUDA_LIBRARY_DIRS} -Wl,-rpath-link,${CUDA_LIBRARY_DIRS}  ${CMAKE_EXE_LINKER_FLAGS}")
set(CMAKE_CUDA_HOST_COMPILER            ${CMAKE_CXX_COMPILER})
set(CUDA_INCLUDE_DIRS                   ${CUDA_DIR}/targets/aarch64-linux/include)


# instruct nvcc to use our cross-compiler
set(CMAKE_CUDA_FLAGS "-ccbin ${CMAKE_CXX_COMPILER} -Xcompiler -fPIC" CACHE STRING "" FORCE)
