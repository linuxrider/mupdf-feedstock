@echo off
setlocal EnableDelayedExpansion

:: The source tarball extracts into a subdirectory of the work directory.
:: Find it by locating the directory that contains platform\win32\mupdf.sln.
set SRCDIR=
for /d %%D in (*) do (
    if exist "%%D\platform\win32\mupdf.sln" set SRCDIR=%%D
)
if "!SRCDIR!"=="" (
    echo ERROR: Could not find mupdf source directory in %CD%
    exit 1
)
pushd "!SRCDIR!"

:: Build MuPDF using the native Visual Studio solution.
:: Uses bundled thirdparty libs (freetype, brotli, jbig2dec, openjpeg,
:: zlib, harfbuzz, lcms2, gumbo-parser, libjpeg, leptonica, tesseract, etc.)
:: rather than conda-provided ones.

set PLAT=x64
set CONFIG=Release
set WINDIR=platform\win32
set OUTDIR=%WINDIR%\%PLAT%\%CONFIG%

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
msbuild %WINDIR%\mupdf.sln ^
    /t:mutool ^
    /p:Configuration=%CONFIG% ^
    /p:Platform=%PLAT% ^
    /p:PlatformToolset=v143 ^
    /p:PreferredToolArchitecture=x64 ^
    /m ^
    /v:m
if errorlevel 1 exit 1

:: --- Install ---

:: mutool executable (tested by the package test suite)
copy /y "%OUTDIR%\mutool.exe" "%LIBRARY_BIN%\"
if errorlevel 1 exit 1

:: static library (for consumers that link against libmupdf)
copy /y "%OUTDIR%\libmupdf.lib" "%LIBRARY_LIB%\"
if errorlevel 1 exit 1

:: public C headers
xcopy /s /y "include\" "%LIBRARY_INC%\"
if errorlevel 1 exit 1

popd
