#!/bin/bash -e
# Build Tensorflow 1.1.0 with CUDA GPU support for macOS, with C++ support.
# Prerequisites:
# - Bazel
# - Python 3.6 from python.org
# - CUDA 8.0
# - cuDNN 6.0 installed to /usr/local/cuda
# - a GPU with Compute Capability 3.0
# Versions can be changed by modifying the configuration below.

distdir="$(pwd)/dist/macos/tensorflow-cuda"
mkdir -p "$distdir"

builddir="$(pwd)/build/tensorflow-cuda"
git clone --depth=1 --branch=v1.1.0 https://github.com/tensorflow/tensorflow "$builddir"
pushd "$builddir"

echo '/Library/Frameworks/Python.framework/Versions/3.6/bin/python3
-march=native
n
n
n
/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages
n
y
/usr/bin/gcc
8.0
/usr/local/cuda
6
/usr/local/cuda/cudnn-6.0
3.0' | ./configure

# Configuration output:
: <<EOF
Please specify the location of python. [Default is /Library/Frameworks/Python.framework/Versions/2.7/bin/python]: /Library/Frameworks/Python.framework/Versions/3.6/bin/python3
Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native]: 
Do you wish to build TensorFlow with Google Cloud Platform support? [y/N] 
No Google Cloud Platform support will be enabled for TensorFlow
Do you wish to build TensorFlow with Hadoop File System support? [y/N] 
No Hadoop File System support will be enabled for TensorFlow
Do you wish to build TensorFlow with the XLA just-in-time compiler (experimental)? [y/N] 
No XLA support will be enabled for TensorFlow
Found possible Python library paths:
  /Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages
Please input the desired Python library path to use.  Default is [/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages]

Using python library path: /Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages
Do you wish to build TensorFlow with OpenCL support? [y/N] 
No OpenCL support will be enabled for TensorFlow
Do you wish to build TensorFlow with CUDA support? [y/N] y
CUDA support will be enabled for TensorFlow
Please specify which gcc should be used by nvcc as the host compiler. [Default is /usr/bin/gcc]: 
Please specify the CUDA SDK version you want to use, e.g. 7.0. [Leave empty to use system default]: 8.0
Please specify the location where CUDA 8.0 toolkit is installed. Refer to README.md for more details. [Default is /usr/local/cuda]: 
Please specify the Cudnn version you want to use. [Leave empty to use system default]: 6
Please specify the location where cuDNN 6 library is installed. Refer to README.md for more details. [Default is /usr/local/cuda]: /usr/local/cuda/cudnn-6.0
Please specify a list of comma-separated Cuda compute capabilities you want to build with.
You can find the compute capability of your device at: https://developer.nvidia.com/cuda-gpus.
Please note that each additional compute capability significantly increases your build time and binary size.
[Default is: "3.5,5.2"]: 3.0
Configuration finished
EOF

# Main build
CMD="bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so"
if ! $CMD; then
    # Link local_config_cuda to fix an abort failure during build
    ln -sfh /usr/local bazel-bin/../../../../local_config_cuda
    $CMD
fi

# Fixup dynamic library paths
for outfile in libtensorflow.so libtensorflow_cc.so; do
    outpath="bazel-bin/tensorflow/$outfile"
    chmod u+w $outpath
    install_name_tool \
        -id "/usr/local/lib/$outfile" \
        -rpath '../local_config_cuda/cuda/lib' '/usr/local/cuda/lib' \
        -rpath '../local_config_cuda/cuda/extras/CUPTI/lib' '/usr/local/cuda/extras/CUPTI/lib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccublas___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccuda_Udriver___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccudnn___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccufft___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccurand___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        "$outpath"
    chmod u-w $outpath
done

for outfile in python/_pywrap_tensorflow_internal.so; do
    outpath="bazel-bin/tensorflow/$outfile"
    chmod u+w $outpath
    install_name_tool \
        -id "/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages/tensorflow/$outfile" \
        -rpath '../local_config_cuda/cuda/lib' '/usr/local/cuda/lib' \
        -rpath '../local_config_cuda/cuda/extras/CUPTI/lib' '/usr/local/cuda/extras/CUPTI/lib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccublas___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccuda_Udriver___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccudnn___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccufft___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccurand___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        -delete_rpath '$ORIGIN/../../_solib_darwin/_U@local_Uconfig_Ucuda_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Slib' \
        "$outpath"
    chmod u-w $outpath
done

# Build output package
bazel-bin/tensorflow/tools/pip_package/build_pip_package "$distdir" --gpu

# Copy output files
cp bazel-bin/tensorflow/libtensorflow{,_cc}.so "$distdir"

# Copy header files
subdir=tensorflow_gpu-1.1.0.data/purelib/tensorflow
unzip "$distdir"/*.whl "$subdir/include/*" -d "/tmp"
mv "/tmp/$subdir/include" "$distdir"

# Copy C++ header files
for header in $(find tensorflow/cc -name \*.h); do
    mkdir -p "$distdir/include/$(dirname ${header})"
    cp "$header" "${distdir}/include/$(dirname ${header})/"
done

cp bazel-genfiles/tensorflow/cc/ops/*.h "$distdir/include/tensorflow/cc/ops"

echo 'All done!'
