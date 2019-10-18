#!/bin/bash

BASE_PATH=$(
	cd "$(dirname $0)"
	pwd
)
DESTDIR=$BASE_PATH/output/
for arch in armeabi armeabi-v7a arm64-v8a x86 x86_64
do
	echo "================================="
	echo "================================="
	echo "============building $arch curl=="
    make clean
	API=12
	if [ $arch == "x86_64" ] || [ $arch == "arm64-v8a" ]; then
		API=21
	fi
	bash config_curl_android.sh $API $arch
	make -j4
	make install
	
	# copy lib
	#mkdir -p "${DESTDIR}/lib/$arch"
    #mv libcurl.a ${DESTDIR}/lib/$arch/libcurl.a

done

# copy header
mkdir -p "${DESTDIR}/include"
cp -r "include/curl" "${DESTDIR}/include/"