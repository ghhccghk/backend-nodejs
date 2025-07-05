[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"
WORKSPACE=$GITHUB_WORKSPACE
HOMEPATH=~
VERSION=$1
ARCH="$2"

case $ARCH in
    arm)
        OUTPUT="armeabi-v7a"
        ;;
    x86)
        OUTPUT="x86"
        ;;
    x86_64)
        OUTPUT="x64"
        ;;
    arm64|aarch64)
        OUTPUT="arm64-v8a"
        ;;
    *)
        echo "Unsupported architecture provided: $ARCH"
        exit 1
        ;;
esac

cd ~/android-ndk-r27c
~/android-ndk-r27c/ndk-build APP_ABI=$OUTPUT NDK_PROJECT_PATH="~/android-ndk-r27c" APP_BUILD_SCRIPT="~/android-ndk-r27c/sources/android/cpufeatures/Android.mk" APP_PLATFORM=29

cd $HOMEPATH
git clone --depth 1 --branch v22.17.0 https://github.com/nodejs/node.git

cd node
patch -p1 < $WORKSPACE/patchs/my_changes.patch

#echo "=====[Patching Node.js]====="
#node $WORKSPACE/node-script/do-gitpatch.js -p $WORKSPACE/patchs/lib_uv_add_on_watcher_queue_updated_v$VERSION.patch
#node $WORKSPACE/node-script/add_arraybuffer_new_without_stl.js deps/v8
#node $WORKSPACE/node-script/make_v8_inspector_export.js

echo "=====[Building Node.js]====="

export CC=clang
export CXX=clang++


#export CXXFLAGS="-stdlib=libc++ -include cstdint"
#export LDFLAGS="-stdlib=libc++ -Wl -z common-page-size=16384"

./android-configure ~/android-ndk-r27c 29 $ARCH
make -j30 LDFLAGS="-Wl,-z,max-page-size=16384 -L~/android-ndk-r27c/obj/local/$OUTPUT -lcpufeatures"

mkdir -p ../puerts-node/nodejs/include
mkdir -p ../puerts-node/nodejs/deps/uv/include
mkdir -p ../puerts-node/nodejs/deps/v8/include

cp src/node.h ../puerts-node/nodejs/include
cp src/node_version.h ../puerts-node/nodejs/include
cp -r deps/uv/include ../puerts-node/nodejs/deps/uv
cp -r deps/v8/include ../puerts-node/nodejs/deps/v8

mkdir -p ../puerts-node/nodejs/lib/Linux/
cp out/Release/libnode* ../puerts-node/nodejs/lib/Linux/
cd ../puerts-node/nodejs/lib/Linux/
#ln -s libnode.so.93 libnode.so
cd -
