BASEDIR ?= /opt/compiler/v1.1-2024-09-30

PREFIX_1 ?= x86_64-unknown-linux-gnu
PREFIX_2 ?= aarch64-unknown-linux-gnu

all:
	gcc sysroot-gcc.c -Wno-unused-result -O3 -o sysroot_gcc
	strip sysroot_gcc
	ls -al sysroot_gcc
	cp sysroot_gcc $(BASEDIR)/$(PREFIX_1)/bin/$(PREFIX_1)-sysroot_gcc
	cp sysroot_gcc $(BASEDIR)/$(PREFIX_1)/bin/$(PREFIX_1)-sysroot_g++
	cp sysroot_gcc $(BASEDIR)/$(PREFIX_2)/bin/$(PREFIX_2)-sysroot_gcc
	cp sysroot_gcc $(BASEDIR)/$(PREFIX_2)/bin/$(PREFIX_2)-sysroot_g++
	$(BASEDIR)/$(PREFIX_1)/bin/$(PREFIX_1)-sysroot_gcc

