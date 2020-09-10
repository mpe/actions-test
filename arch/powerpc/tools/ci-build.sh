#!/bin/bash

if [[ -z "$GITHUB_WORKSPACE" || -z "$TARGET" || -z "$IMAGE" || -z "$SUBARCH" ]]; then
    echo "Error: required environment variables not set!"
    exit 1
fi

cmd="docker run --rm "
cmd+="--network none "
cmd+="-w /linux "
cmd+="-v $GITHUB_WORKSPACE/linux:/linux:ro "

cmd+="-e ARCH "
cmd+="-e JFACTOR=$(nproc) "
cmd+="-e KBUILD_BUILD_TIMESTAMP=$(date +%Y-%m-%d) "
cmd+="-e CLANG "
cmd+="-e SPARSE "

if [[ -n "$MODULES" ]]; then
    cmd+="-e MODULES=$MODULES "
fi

if [[ -n "$DEFCONFIG" ]]; then
    cmd+="-e DEFCONFIG=${DEFCONFIG}_defconfig "
fi

if [[ "$SUBARCH" == "ppc64" ]]; then
    cross="powerpc-linux-gnu-"
else
    cross="powerpc64le-linux-gnu-"
fi
cmd+="-e CROSS_COMPILE=$cross "

mkdir -p $GITHUB_WORKSPACE/output
cmd+="-v $GITHUB_WORKSPACE/output:/output:rw "

user=$(stat -c "%u:%g" $GITHUB_WORKSPACE/output)
cmd+="-u $user "

if [[ -n "$TARGETS" ]]; then
    cmd+="-e TARGETS=$TARGETS "
fi

if [[ "$TARGET" == "kernel" ]]; then
    cmd+="-e QUIET=1 "
fi

cmd+="linuxppc/build:$IMAGE-$(uname -m) "
cmd+="/bin/container-build.sh $TARGET"

(set -x; $cmd)

rc=$?

if [[ -n "$SPARSE" ]]; then
    cat $GITHUB_WORKSPACE/output/sparse.log
fi

exit $rc
