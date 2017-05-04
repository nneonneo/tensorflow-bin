## Tensorflow Binaries

Tensorflow is finicky to get working and setup, and the official binaries have spotty version coverage.

This repo is intended to be a good stable source of both binaries and build scripts which can be used to build binaries with less pain.

## Building from source

To build from source, install Bazel (https://bazel.build/) for your platform and any additional dependencies listed in the target build script.

Then, from this directory, simply run the script (e.g. `./build-macos-cpu.sh`) and wait a while. Output will be placed in the `dist` directory labelled with your platform and build type.

## Using the binaries

For Python, install the wheel with `pip`.

For C++:

- On macOS/Linux, place `libtensorflow.so` and `libtensorflow_cc.so` in `/usr/local/lib`, and use `-I dist/.../include` and `-l tensorflow_cc` when compiling C++ programs.
- On Windows, TBA
