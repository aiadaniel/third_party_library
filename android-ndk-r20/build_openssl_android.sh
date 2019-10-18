#! /bin/bash

MINIMUM_ANDROID_SDK_VERSION=$1
MINIMUM_ANDROID_64_BIT_SDK_VERSION=$2
OPENSSL_FULL_VERSION="openssl-1.1.1b"

BUILD_DIR=./output
INSTALL_DIR=./output2

if [ ! -f "$OPENSSL_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.openssl.org/source/$OPENSSL_FULL_VERSION.tar.gz
fi
tar -xzf $OPENSSL_FULL_VERSION.tar.gz

(cd $OPENSSL_FULL_VERSION;

 if [ ! ${MINIMUM_ANDROID_SDK_VERSION} ]; then
     echo "MINIMUM_ANDROID_SDK_VERSION was not provided, include and rerun"
     exit 1
 fi

 if [ ! ${MINIMUM_ANDROID_64_BIT_SDK_VERSION} ]; then
     echo "MINIMUM_ANDROID_64_BIT_SDK_VERSION was not provided, include and rerun"
     exit 1
 fi

 if [ ! ${ANDROID_NDK_ROOT} ]; then
     echo "ANDROID_NDK_ROOT environment variable not set, set and rerun"
     exit 1
 fi



 
 do_build() {
	TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64
	export PATH="$PATH":$TOOLCHAIN/$TOOLCHAIN_PREFIX/bin:$TOOLCHAIN/bin
	
	make clean
	./Configure $PLATFORM_TARGET $OPTIONS -fuse-ld="$TOOLCHAIN/$TOOLCHAIN_PREFIX/bin/ld"
	make
	make install DESTDIR=$INSTALL_DIR
 }

 for ANDROID_TARGET_PLATFORM in armeabi armeabi-v7a x86 x86_64 arm64-v8a
 do
     echo "Building for libcrypto.a and libssl.a for ${ANDROID_TARGET_PLATFORM}"
     case "${ANDROID_TARGET_PLATFORM}" in
         armeabi)
             TOOLCHAIN_PREFIX=arm-linux-androideabi
             OPTIONS="--target=armv5te-linux-androideabi -mthumb -fPIC -latomic -D__ANDROID_API__=$MINIMUM_ANDROID_SDK_VERSION"
			 DESTDIR="$BUILD_DIR/armeabi"
             PLATFORM_TARGET="android-arm"
             ;;
         armeabi-v7a)
             TOOLCHAIN_PREFIX=arm-linux-androideabi
             OPTIONS="--target=armv7a-linux-androideabi -Wl,--fix-cortex-a8 -fPIC -D__ANDROID_API__=$MINIMUM_ANDROID_SDK_VERSION"
			 DESTDIR="$BUILD_DIR/armeabi-v7a"
             PLATFORM_TARGET="android-arm"
             ;;
         x86)
             TOOLCHAIN_PREFIX=i686-linux-android
             OPTIONS="-fPIC -D__ANDROID_API__=$MINIMUM_ANDROID_SDK_VERSION"
			 DESTDIR="$BUILD_DIR/x86"
             PLATFORM_TARGET="android-x86"
             ;;
         x86_64)
             TOOLCHAIN_PREFIX=x86_64-linux-android
             OPTIONS="-fPIC -D__ANDROID_API__=$MINIMUM_ANDROID_SDK_VERSION"
			 DESTDIR="$BUILD_DIR/x86_64"
             PLATFORM_TARGET="android-x86_64"
             ;;
         arm64-v8a)
             TOOLCHAIN_PREFIX=aarch64-linux-android
             OPTIONS="-fPIC -D__ANDROID_API__=$MINIMUM_ANDROID_SDK_VERSION"
			 DESTDIR="$BUILD_DIR/arm64-v8a"
             PLATFORM_TARGET="android-arm64"
             ;;
         *)
             echo "Unsupported build platform:${ANDROID_TARGET_PLATFORM}"
             exit 1
     esac
	 
	 rm -rf $DESTDIR

	 do_build

	 # copy lib
	 mkdir -p "${DESTDIR}/lib"
     mv libcrypto.a ${DESTDIR}/lib/libcrypto.a
     mv libssl.a ${DESTDIR}/lib/libssl.a

     # copy header
     mkdir -p "${DESTDIR}/include"
     cp -r "include/openssl" "${DESTDIR}/include/"
 done 
)