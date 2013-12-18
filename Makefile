TARGET_ARCH=x86_64
HOST_ARCH=x86

HOST_OUT=output/host
PRODUCT_OUT=output/product
TARGET_OUT=output/target
HOST_OUT_EXECUTABLES=$(HOST_OUT)/bin
TARGET_OUT_EXECUTABLES=$(TARGET_OUT)/bin
HOST_OUT_SHARED_LIBRARIES=$(HOST_OUT)/lib
TARGET_OUT_SHARED_LIBRARIES=$(TARGET_OUT)/lib
HOST_SHLIB_SUFFIX=.so


BUILD_SYSTEM=build/core
DALVIK_VM_LIB='libart.so'

.PHONY: default
default: build-art-target

include build/core/config.mk

include build/core/combo/HOST_linux-x86.mk
include build/core/definitions.mk
include build/core/dex_preopt.mk
include art/Android.mk

$(eval $(call build-libarttest,target))
