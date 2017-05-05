@ECHO OFF

REM Prerequisites:
REM - Python 3.6
REM - Git (on PATH)
REM - CMake (on PATH)
REM - Swig (swigwin)
REM - Visual Studio 2015

REM Compile your programs with
REM   -DEIGEN_AVOID_STL_ARRAY -DNOMINMAX -D_WIN32_WINNT=0x0A00 -DLANG_CXX11 -DCOMPILER_MSVC -DWIN32 -DOS_WIN -D_MBCS -DWIN64 -DWIN32_LEAN_AND_MEAN -DNOGDI -DPLATFORM_WINDOWS -DTENSORFLOW_USE_EIGEN_THREADPOOL -DEIGEN_HAS_C99_MATH -D_ITERATOR_DEBUG_LEVEL=0 -DNDEBUG /O2 /bigobj /EHsc
REM and add the paths
REM   -I %DISTDIR%\include %DISTDIR%\tensorflow.lib

REM Setup build environment
call "c:\Program Files (x86)\Microsoft Visual Studio 14.0\vc\bin\amd64\vcvars64.bat"

set "MYDIR=%~dp0"
set "DISTDIR=%MYDIR%\dist\windows\tensorflow"
mkdir "%DISTDIR%"

REM Download Tensorflow
set "BUILDDIR=%MYDIR%\build\tensorflow"
git clone --depth=1 --branch=v1.1.0 https://github.com/tensorflow/tensorflow "%BUILDDIR%" || exit /B
pushd "%BUILDDIR%"

REM Apply patches
git am "%MYDIR%\build-windows-0001.patch" || exit /B
git am "%MYDIR%\build-windows-0002.patch" || exit /B

REM Build with CMake
mkdir tensorflow\contrib\cmake\build
pushd tensorflow\contrib\cmake\build
cmake .. -A x64 -DCMAKE_BUILD_TYPE=Release ^
  -DSWIG_EXECUTABLE=C:/tools/swigwin-3.0.12/swig.exe ^
  -DPYTHON_EXECUTABLE="C:/Program Files/Python36/python.exe" ^
  -DPYTHON_LIBRARIES="C:/Program Files/Python36/libs/python36.lib" ^
  -Dtensorflow_BUILD_SHARED_LIB=TRUE || exit /B

REM Build project
MSBuild /p:Configuration=Release tensorflow.vcxproj || exit /B
MSBuild /p:Configuration=Release tf_python_build_pip_package.vcxproj || exit /B

REM Copy headers and re-run package setup
call :copydir "%BUILDDIR%\tensorflow\core" *.h "%cd%\tf_python\tensorflow\core"
call :copydir "%BUILDDIR%\tensorflow\stream_executor" *.h "%cd%\tf_python\tensorflow\stream_executor"
call :copydir "%cd%\tensorflow" *.h "%cd%\tf_python\tensorflow"
call :copydir "%cd%\protobuf\src\protobuf\src\google\protobuf" *.h "%cd%\tf_python\google\protobuf\src\google\protobuf"
call :copydir "%cd%\external\eigen_archive" * "%cd%\tf_python\external\eigen_archive"
call :copydir "%BUILDDIR%\third_party\eigen3" * "%cd%\tf_python\third_party\eigen3"

pushd tf_python
python setup.py bdist_wheel
popd

REM Copy Python output
copy tf_python\dist\*.whl "%DISTDIR%"

REM Copy C++ output and headers
for %%i in (cc core stream_executor) do (
  call :copydir "%BUILDDIR%\tensorflow\%%i" *.h "%DISTDIR%\include\tensorflow\%%i"
  call :copydir "%cd%\tensorflow\%%i" *.h "%DISTDIR%\include\tensorflow\%%i"
)

pushd external\eigen_archive
for /D %%i in (*) do (
  call :copydir "%cd%\%%i" * "%DISTDIR%\include\%%i"
)
popd

call :copydir "%BUILDDIR%\third_party\eigen3" * "%DISTDIR%\include\third_party\eigen3"
call :copydir "%cd%\protobuf\src\protobuf\src\google\protobuf" *.h "%DISTDIR%\include\google\protobuf"

REM Copy C++ output
copy Release\tensorflow.dll "%DISTDIR%"
copy Release\tensorflow.lib "%DISTDIR%"
copy Release\tensorflow.exp "%DISTDIR%"
REM copy Release\tensorflow_static.lib "%DISTDIR%"

popd
popd

exit /B %ERRORLEVEL%

REM Functions

:copydir
REM copy a partial directory tree.
REM Arguments: [src-root] [mask] [dst-root]
REM   Files from src-root matching mask (recursively) are copied
REM   to dst-root, maintaining directory structure.
REM   src-root and dst-root should be absolute.
REM Usage example: copydir C:\tools\boost-1.39.0\boost *.hpp E:\devel\include\boost
REM   copies .hpp files to E:\devel\include\boost (e.g. creating E:\devel\include\boost\lambda\lambda.hpp).
mkdir %3
set SRCROOT="%~1"
set DSTROOT="%~3"
forfiles /p %SRCROOT% /s /m "%~2" /c "cmd /c if @isdir==FALSE pushd %%DSTROOT%% & for %%F in (@relpath) do @mkdir \"%%~dpF\" & copy %%SRCROOT%%\%%F %%F"
exit /B 0
