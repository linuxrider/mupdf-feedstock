@echo on
setlocal EnableDelayedExpansion

:: Get access to devenv
@REM call "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat"

set "SLN_PLAT=%CMAKE_GENERATOR_PLATFORM%"
set "SLN_TOOLSET=%CMAKE_GENERATOR_TOOLSET%"
set "SLN_DIR=platform\win32"
set "SLN_FILE=mupdf.sln"
set "CONFIG=Release"

:: Patch Toolset
for /R "%SLN_DIR%" %%f in (*.vcxproj) do (
    echo Patching %%f ...
    powershell -Command "(Get-Content '%%f') -replace '<PlatformToolset>.*</PlatformToolset>', '<PlatformToolset>%SLN_TOOLSET%</PlatformToolset>' | Set-Content '%%f'"
)


:: Build mutool via MSBuild. Project references pull in the full dependency chain:
::   mutool -> libmutool -> libmupdf -> libthirdparty  (brotli, freetype, jbig2dec,
::                                                      libjpeg, openjpeg, zlib,
::                                                      gumbo-parser, lcms2, mujs)
::                                   -> libresources   (embedded fonts)
::                                   -> libharfbuzz
::                                   -> libpkcs7
::                                   -> libextract
::                                   -> libmubarcode
::                                   -> libtesseract -> libleptonica
::                          -> libmuthreads
::                          -> sodochandler
msbuild %SLN_DIR%\%SLN_FILE% ^
    /p:Configuration=%CONFIG% ^
    /p:Platform=%SLN_PLAT% ^
    /p:PlatformToolset=%SLN_TOOLSET% ^
    /t:mutool ^
    /verbosity:normal
if errorlevel 1 exit 1

:: Build Python bindings via pip install.
:: setup.py internally runs scripts/mupdfwrap.py with actions 0,1,2,3:
::   0: Generate C++ source using libclang (needs python-clang)
::   1: Build mupdfcpp64.dll using devenv
::   2: Generate Python wrapper using SWIG
::   3: Build _mupdf.pyd using cl.exe/link.exe

:: Python 3.8+ no longer searches PATH when loading DLLs via ctypes.
:: Copy libclang.dll to %PREFIX% (python.exe's directory) so that
:: clang.cindex can find it via LoadLibrary().
copy "%LIBRARY_BIN%\libclang-13.dll" "%PREFIX%\libclang.dll"
if errorlevel 1 (
    echo "WARNING: Could not copy libclang.dll from %LIBRARY_BIN% to %PREFIX%"
    dir "%LIBRARY_BIN%\libclang*"
    exit 1
)



set MUPDF_SETUP_USE_CLANG_PYTHON=1
set MUPDF_SETUP_USE_SWIG=1
pip install . --no-deps --no-build-isolation
if errorlevel 1 exit 1

:: --- Install mutool and headers ---
cmake -E make_directory %LIBRARY_BIN%
if errorlevel 1 exit 1
cmake -E copy %SRC_DIR%\%SLN_DIR%\%SLN_PLAT%\%CONFIG%\mutool.exe %LIBRARY_BIN%\
if errorlevel 1 exit 1
cmake -E make_directory %LIBRARY_INC%
if errorlevel 1 exit 1
cmake -E copy_directory %SRC_DIR%\include %LIBRARY_INC%
if errorlevel 1 exit 1
