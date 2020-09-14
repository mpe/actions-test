#!/bin/bash

if [[ -z "$TARGET" || -z "$IMAGE" || -z "$SUBARCH" ]]; then
    echo "Error: required environment variables not set!"
    exit 1
fi

cmd="docker run --rm "
cmd+="--network none "
cmd+="-w /linux "

linux_dir=$(realpath $(dirname $0))/../../../
cmd+="-v $linux_dir:/linux:ro "

cmd+="-e ARCH "
cmd+="-e JFACTOR=$(nproc) "
cmd+="-e KBUILD_BUILD_TIMESTAMP=$(date +%Y-%m-%d) "
cmd+="-e CLANG "
cmd+="-e SPARSE "

if [[ -n "$MODULES" ]]; then
    cmd+="-e MODULES=$MODULES "
fi

if [[ -n "$DEFCONFIG" ]]; then
    if [[ $DEFCONFIG != *config ]]; then
	DEFCONFIG=${DEFCONFIG}_defconfig
    fi

    cmd+="-e DEFCONFIG=${DEFCONFIG} "
fi

if [[ "$SUBARCH" == "ppc64" ]]; then
    cross="powerpc-linux-gnu-"
else
    cross="powerpc64le-linux-gnu-"
fi
cmd+="-e CROSS_COMPILE=$cross "

mkdir -p $HOME/output
cmd+="-v $HOME/output:/output:rw "

user=$(stat -c "%u:%g" $HOME/output)
cmd+="-u $user "

if [[ -n "$CCACHE" ]]; then
    cmd+="-v $HOME/.ccache:/ccache:rw "
    cmd+="-e CCACHE_DIR=/ccache "
    cmd+="-e CCACHE=1 "
fi

if [[ -n "$TARGETS" ]]; then
    cmd+="-e TARGETS=$TARGETS "
fi

if [[ -n "$INSTALL" ]]; then
    cmd+="-e INSTALL=$INSTALL "
fi

if [[ "$TARGET" == "kernel" ]]; then
    cmd+="-e QUIET=1 "
fi

cmd+="linuxppc/build:$IMAGE-$(uname -m) "
cmd+="/bin/container-build.sh $TARGET"

(set -x; $cmd)

rc=$?

if [[ -n "$SPARSE" ]]; then
    cat $HOME/output/sparse.log
fi

exit $rc
