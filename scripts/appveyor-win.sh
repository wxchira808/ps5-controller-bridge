#!/bin/bash

set -xe

BUILD_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
BUILD_ROOT="$(echo $BUILD_ROOT | sed 's|^/\([a-z]\)|\1:|g')" # replace /c/... by c:/... for cmake to understand it
echo "BUILD_ROOT=$BUILD_ROOT"

download_file() {
	local url="$1"
	local output="$2"
	if command -v wget >/dev/null 2>&1; then
		wget -O "$output" "$url"
	else
		curl.exe -L "$url" -o "$output"
	fi
}

extract_zip() {
	local archive="$1"
	local destination="$2"
	mkdir -p "$destination"
	powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '$archive' -DestinationPath '$destination' -Force"
}

find_python() {
	for candidate in /d/Users/MSI/AppData/Local/Programs/Python/Python310/python.exe /c/Python312/python.exe /c/Python314/python.exe; do
		if [ -f "$candidate" ]; then
			echo "${candidate//\//\\}"
			return 0
		fi
	done
	return 1
}

find_qt_path() {
	for candidate in /c/Qt/6.8.3/msvc2022_64 /c/Qt/6.8.2/msvc2022_64 /c/Qt/6.8.1/msvc2022_64 /c/Qt/6.8.0/msvc2022_64 /c/Qt/6.7.3/msvc2022_64 /c/Qt/6.7.2/msvc2022_64 /c/Qt/6.7.1/msvc2022_64 /c/Qt/6.7.0/msvc2022_64 /c/Qt/6.6.3/msvc2022_64 /c/Qt/6.6.2/msvc2022_64 /c/Qt/6.6.1/msvc2022_64 /c/Qt/6.6.0/msvc2022_64 /d/Qt/6.8.3/msvc2022_64 /d/Qt/6.8.2/msvc2022_64 /d/Qt/6.7.3/msvc2022_64 /d/Qt/6.6.3/msvc2022_64; do
		if [ -d "$candidate" ]; then
			echo "${candidate//\//\\}"
			return 0
		fi
	done
	return 1
}

mkdir ninja && cd ninja
download_file https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip ninja-win.zip
extract_zip ninja-win.zip .
cd ..

mkdir yasm && cd yasm
download_file https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip nasm.zip
extract_zip nasm.zip .
cd ..

QT_PATH="$(find_qt_path)"
if [ -z "$QT_PATH" ]; then
	echo "Qt 6 MSVC build not found. Install a Qt 6 msvc2022_64 kit and rerun."
	exit 1
fi

export PATH="$PWD/ninja:$PWD/yasm:${QT_PATH//\\//}/bin:$PATH"

scripts/build-ffmpeg.sh . --target-os=win64 --arch=x86_64 --toolchain=msvc

git clone https://github.com/xiph/opus.git && cd opus && git checkout ad8fe90db79b7d2a135e3dfd2ed6631b0c5662ab
mkdir build && cd build
cmake \
	-G Ninja \
	-DCMAKE_C_COMPILER=cl \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="$BUILD_ROOT/opus-prefix" \
	..
ninja
ninja install
cd ../..

download_file https://mirror.firedaemon.com/OpenSSL/openssl-1.1.1q.zip openssl-1.1.1q.zip
extract_zip openssl-1.1.1q.zip .

# We need to avoid SDL Versions > 2.0.20 on Windows, since there's a problem with resampling using
# the WASAPI audio driver: https://github.com/libsdl-org/SDL/issues/6326
# TODO: Update to the latest version once 2.26.0 is released with a fix
download_file https://www.libsdl.org/release/SDL2-devel-2.0.20-VC.zip SDL2-devel-2.0.20-VC.zip
extract_zip SDL2-devel-2.0.20-VC.zip .
export SDL_ROOT="$BUILD_ROOT/SDL2-2.0.20"
export SDL_ROOT=${SDL_ROOT//[\\]//}
echo "set(SDL2_INCLUDE_DIRS \"$SDL_ROOT/include\")
set(SDL2_LIBRARIES \"$SDL_ROOT/lib/x64/SDL2.lib\")
set(SDL2_LIBDIR \"$SDL_ROOT/lib/x64\")
include($SDL_ROOT/cmake/sdl2-config-version.cmake)" > "$SDL_ROOT/SDL2Config.cmake"

mkdir protoc && cd protoc
download_file https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-win64.zip protoc-3.9.1-win64.zip
extract_zip protoc-3.9.1-win64.zip .
cd ..
export PATH="$PWD/protoc/bin:$PATH"

PYTHON="$(find_python)"
if [ -z "$PYTHON" ]; then
	echo "Python interpreter not found. Install Python and rerun."
	exit 1
fi
"$PYTHON" -m pip install protobuf==3.19.5

COPY_DLLS="$PWD/openssl-1.1/x64/bin/libcrypto-1_1-x64.dll $PWD/openssl-1.1/x64/bin/libssl-1_1-x64.dll $SDL_ROOT/lib/x64/SDL2.dll"

echo "-- Configure"

# SDL version discovery doesn't work with 2.0.20, so we just remove the version check ¯\_(ツ)_/¯
sed -i -e 's/find_package(SDL2 2.0.16 MODULE REQUIRED)/find_package(SDL2 MODULE REQUIRED)/g' gui/CMakeLists.txt

mkdir build && cd build


cmake \
	-G Ninja \
	-DCMAKE_C_COMPILER=cl \
	-DCMAKE_C_FLAGS="-we4013" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_PREFIX_PATH="$BUILD_ROOT/ffmpeg-prefix;$BUILD_ROOT/opus-prefix;$BUILD_ROOT/openssl-1.1/x64;$QT_PATH;$SDL_ROOT" \
	-DPYTHON_EXECUTABLE="$PYTHON" \
	-DCHIAKI_ENABLE_TESTS=ON \
	-DCHIAKI_ENABLE_CLI=OFF \
	-DCHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER=ON \
	..

echo "-- Build"

ninja

echo "-- Test"

cp $COPY_DLLS test/
test/chiaki-unit.exe

cd ..


# Deploy

echo "-- Deploy"

mkdir Chiaki && cp build/gui/chiaki.exe Chiaki
mkdir Chiaki-PDB && cp build/gui/chiaki.pdb Chiaki-PDB

"$QT_PATH/bin/windeployqt.exe" Chiaki/chiaki.exe
cp -v $COPY_DLLS Chiaki
