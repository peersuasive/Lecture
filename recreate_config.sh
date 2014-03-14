#!/usr/bin/env bash

os=$(uname -s)

case $os in
    *Linux*)
        OS=lin;;
    *Darwin*)
        OS=osx;;
    *[Cc][Yy][Gg][Ww][Ii]*)
        OS=win;;
    *[Mm][Ii][Nn][Gg][Ww]*)
        OS=win;;
    *)
        OS=lin;;
esac

_failed() {
    local msg=${@:+: $@}
    echo "FAILED${msg}" >&2
    exit 1
}

home=$(dirname $(readlink -f "$0"))

echo "$home"
! [[ -d "$home" && "$home" =~ ^/[^/]+(/)? ]] && _failed "Can't find a valid root"

pushd "$home"/ &>/dev/null

echo "Updating submodules..."
git submodule update --init --recursive


echo "Creating links..."
cd "$home"/src
ln -sf ../luce/Source/lua/luce.lua .
mkdir -p luce
cd luce/
ln -sf ../../luce/Source/lua/luce/* .
ln -sf ../../luce/Builds/Linux/build/libluce.a core.so
ln -sf ../../luce/Builds/Linux/build/libluce_d.a core_d.so

cd "$home"/src/embed/
ln -sf ../config/Makefile.* .
ln -sf ../config/squishy .
ln -sf ../config/sources .
echo "(ignore warning if any)"
ln -sf ../. classes
ln -sf ../main.lua .

cd "$home"/src/embed/luajit/src/
ln -sf ../../../config/luajit/* .


cd "$home"/src/config/sources
## linux
if [[ "$OS" == lin ]]
then
    echo "Building Luce for Linux..."
    pushd "$home"/luce/Builds/Linux &>/dev/null
    make -j5 && make -j5 CONFIG=Debug || _failed "Can't compile Luce"
    popd &>/dev/null
    ln -sf ../../../luce/Builds/Linux/build/intermediate/Release/libcore_lin.a .

## adapt to your config/compiler/IDE and result paths
elif [[ "$OS" == win ]]
then
    :
    #ln -sf ../../../luce/Builds/VisualStudio2010/build/intermediate/Release/libcore_lin.a .
elif [[ "$OS" == osx ]]
then
    :
    #ln -sf ../../../luce/Builds/MacOSX/build/intermediate/Release/libcore_lin.a .
elif [[ "$OS" == ios ]]
then
    :
    #ln -sf ../../../luce/Builds/iOS/build/intermediate/Release/libcore_lin.a .
elif [[ "$OS" == android ]]
then
    :
    ## Android is a bit special and not yet included
    #mkdir -p android
    #cd android
    #ln -sf ../../../../luce/Builds/Android/libs/armeabi-v7a/libluce_jni.so
fi

echo "Building libarchive.a"
cd "$home"/3rd/libarchive
! [[ -r configure ]] && { ./build/autogen.sh || exit 1; }
if ! [[ -f .libs/libarchive.a ]]
then
    ./configure --disable-acl --disable-xattr --enable-static --disable-shared --with-pic --without-lzmadec --without-iconv --without-lzma --without-lzo2 --without-nettle --without-openssl --without-xml2 --without-expat --without-bz2lib || _failed

    make -j4 || exit 1
    cd "$home"/src/config/sources/
    ln "$home"/3rd/libarchive/.libs/libarchive.a libarchive_${OS}.a
fi

popd &>/dev/null
echo OK
