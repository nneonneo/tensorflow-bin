#!/bin/bash -e
# Build Tensorflow 1.1.0 without GPU support for macOS, with C++ support.
# Prerequisites:
# - Bazel
# - Python 3.6 from python.org
# Versions can be changed by modifying the configuration below.

distdir="$(pwd)/dist/macos/tensorflow"
mkdir -p "$distdir"

builddir="$(pwd)/build/tensorflow"
git clone --depth=1 --branch=v1.1.0 https://github.com/tensorflow/tensorflow "$builddir"
pushd "$builddir"

echo '/Library/Frameworks/Python.framework/Versions/3.6/bin/python3
-march=native
n
n
n
/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages
n
n' | ./configure

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
Do you wish to build TensorFlow with CUDA support? [y/N] 
No CUDA support will be enabled for TensorFlow
Configuration finished
EOF

# Main build
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package //tensorflow:libtensorflow.so //tensorflow:libtensorflow_cc.so

# Fixup dynamic library paths
for outfile in libtensorflow.so libtensorflow_cc.so; do
    outpath="bazel-bin/tensorflow/$outfile"
    chmod u+w $outpath
    install_name_tool \
        -id "/usr/local/lib/$outfile" \
        "$outpath"
    chmod u-w $outpath
done

for outfile in python/_pywrap_tensorflow_internal.so; do
    outpath="bazel-bin/tensorflow/$outfile"
    chmod u+w $outpath
    install_name_tool \
        -id "/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages/tensorflow/$outfile" \
        "$outpath"
    chmod u-w $outpath
done

# Build output package
bazel-bin/tensorflow/tools/pip_package/build_pip_package "$distdir"

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
