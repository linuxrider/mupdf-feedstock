@echo off
setlocal EnableDelayedExpansion

set "SLN_PLAT=%CMAKE_GENERATOR_PLATFORM%"
set "SLN_TOOLSET=%CMAKE_GENERATOR_TOOLSET%"
set "SLN_DIR=platform\win32"
set "SLN_FILE=mupdf.sln"
set "CONFIG=Release"

:: Build MuPDF using the native Visual Studio solution.
:: Uses bundled thirdparty libs (freetype, brotli, jbig2dec, openjpeg,
:: zlib, harfbuzz, lcms2, gumbo-parser, libjpeg, leptonica, tesseract, etc.)
:: rather than conda-provided ones.



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

:: --- Install ---
cmake -E make_directory %LIBRARY_BIN%
if errorlevel 1 exit 1
cmake -E copy %SRC_DIR%\%SLN_DIR%\%SLN_PLAT%\%CONFIG%\mutool.exe %LIBRARY_BIN%\
if errorlevel 1 exit 1
cmake -E make_directory %LIBRARY_LIB%
if errorlevel 1 exit 1
cmake -E copy %SRC_DIR%\%SLN_DIR%\%SLN_PLAT%\%CONFIG%\libmupdf.lib %LIBRARY_LIB%\
if errorlevel 1 exit 1
cmake -E make_directory %LIBRARY_INC%
if errorlevel 1 exit 1
cmake -E copy_directory %SRC_DIR%\include %LIBRARY_INC%
if errorlevel 1 exit 1
