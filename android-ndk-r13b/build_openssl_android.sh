#!/bin/bash

BASE_PATH=$(
	cd "$(dirname $0)"
	pwd
)
SSL_PATH="$BASE_PATH"
BUILD_PATH="$BASE_PATH/tmp"
OUT_PATH="$BASE_PATH/output"

checkExitCode() {
	if [ $1 -ne 0 ]; then
		echo "Error building openssl library"
		cd $BASE_PATH
		exit $1
	fi
}
safeMakeDir() {
	if [ ! -x "$1" ]; then
		mkdir -p "$1"
	fi
}

## Android NDK
#export ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"

if [ -z "$ANDROID_NDK_ROOT" ]; then
	echo "Please set your ANDROID_NDK_ROOT environment variable first"
	exit 1
fi

## Build OpenSSL

# compile $1 ABI $2 SYSROOT $3 TOOLCHAIN $4 MACHINE $5 SYSTEM $6 ARCH $7 CROSS_COMPILE
# http://wiki.openssl.org/index.php/Android
# http://doc.qt.io/qt-5/opensslsupport.html
compile() {
	cd $SSL_PATH
	ABI=$1
	SYSROOT=$2
	TOOLCHAIN=$3
	MACHINE=$4
	SYSTEM=$5
	ARCH=$6
	CROSS_COMPILE=$7
	# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
	export SYSROOT=$SYSROOT
	export PATH="$TOOLCHAIN":"$PATH"
	# OpenSSL Configure
	export CROSS_COMPILE=$CROSS_COMPILE
	export ANDROID_DEV=$SYSROOT/usr
	export HOSTCC=gcc
	# Most of these should be OK (MACHINE, SYSTEM, ARCH).
	export MACHINE=$MACHINE
	export SYSTEM=$SYSTEM
	export ARCH=$ARCH
	# config
	#safeMakeDir $BUILD_PATH/$ABI
	checkExitCode $?
	./Configure $ARCH shared no-ssl2 no-ssl3 no-comp no-hw no-engine --prefix=$OUT_PATH/$ABI
	checkExitCode $?
	# clean
	make clean
	checkExitCode $?
	# make
	make -j4 depend
	checkExitCode $?
	make -j4 all
	checkExitCode $?
	# install
	safeMakeDir $OUT_PATH/$ABI
	make install
	checkExitCode $?
	cd $BASE_PATH
}

# check system
host=$(uname | tr 'A-Z' 'a-z')
if [ $host = "darwin" ] || [ $host = "linux" ]; then
	echo "system: $host"
else
	echo "unsupport system, only support Mac OS X and Linux now."
	exit 1
fi

#APP_ABI=(armeabi armeabi-v7a x86 x86_64 arm64-v8a)
APP_ABI=(armeabi armeabi-v7a)
for abi in ${APP_ABI[*]}; do
	case $abi in
	armeabi)
		compile $abi "$ANDROID_NDK_ROOT/platforms/android-12/arch-arm" "$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/$host-x86_64/bin" "arm" "android" "android-arm" "arm-linux-androideabi-"
		;;
	armeabi-v7a)
		compile $abi "$ANDROID_NDK_ROOT/platforms/android-12/arch-arm" "$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/$host-x86_64/bin" "armv7" "android" "android-arm" "arm-linux-androideabi-"
		;;
	x86)
		compile $abi "$ANDROID_NDK_ROOT/platforms/android-12/arch-x86" "$ANDROID_NDK_ROOT/toolchains/x86-4.9/prebuilt/$host-x86_64/bin" "i686" "android" "android-x86" "i686-linux-android-"
		;;
	x86_64)
		compile $abi "$ANDROID_NDK_ROOT/platforms/android-21/arch-x86_64" "$ANDROID_NDK_ROOT/toolchains/x86_64-4.9/prebuilt/$host-x86_64/bin" "x86_64" "android" "android-x86_64" "x86_64-linux-android-"
		;;
	arm64-v8a)
		compile $abi "$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64" "$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/$host-x86_64/bin" "arm64" "android64" "android-arm64" "aarch64-linux-android-"
		;;
	*)
		echo "Error APP_ABI"
		exit 1
		;;
	esac
done

cd $BASE_PATH
exit 0