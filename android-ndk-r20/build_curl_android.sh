#!/bin/bash

DESTDIR=./output/
for arch in armeabi armeabi-v7a arm64-v8a x86 x86_64
do
    make clean
	bash config_curl_android.sh $arch
	make
	
	# copy lib
	mkdir -p "${DESTDIR}/lib/$arch"
    mv libcurl.a ${DESTDIR}/lib/$arch/libcrul.a

    # copy header
    mkdir -p "${DESTDIR}/include"
    cp -r "include/curl" "${DESTDIR}/include/"
done