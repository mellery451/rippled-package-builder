#!/usr/bin/env bash
set -ex

export DEBIAN_FRONTEND="noninteractive"

source /etc/os-release
if [[ "${VERSION_ID}" == "18.04" || "${VERSION_ID}" == "16.04" ]] ; then
    echo "setup for ${PRETTY_NAME}"
else
    echo "${VERSION} not supported"
    exit 1
fi

apt -y update
apt -y install software-properties-common wget
apt -y upgrade
if [[ "${VERSION_ID}" == "18.04" ]] ; then
    apt-add-repository -y multiverse
    apt-add-repository -y universe
elif [[ "${VERSION_ID}" == "16.04" ]] ; then
    add-apt-repository -y ppa:ubuntu-toolchain-r/test
fi
apt-get -y update

apt -y install  \
    make cmake ninja-build ccache \
    protobuf-compiler libprotobuf-dev libssl-dev libzstd-dev \
    python-pip \
    gdb gdbserver \
    libstdc++6 \
    flex bison graphviz graphviz-dev \
    xauth libgl1-mesa-dev mesa-common-dev xvfb \
    libicu-dev texinfo \
    java-common javacc \
    gcc-7 g++-7 \
    gcc-8 g++-8 \
    dpkg-dev debhelper devscripts fakeroot \
    debmake git-buildpackage dh-make gitpkg debsums \
    dh-buildinfo dh-make dh-systemd

update-alternatives --install \
    /usr/bin/gcc gcc /usr/bin/gcc-7 40 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
    --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-7 \
    --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-7 \
    --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-7 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-7 \
    --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-7 \
    --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-7
update-alternatives --install \
    /usr/bin/gcc gcc /usr/bin/gcc-8 20 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
    --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-8 \
    --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-8 \
    --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-8 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-8 \
    --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-8 \
    --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-8
update-alternatives --auto gcc

update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-7 40
update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-8 20
update-alternatives --auto cpp

if [[ "${VERSION_ID}" == "18.04" ]] ; then
    apt -y install binutils
elif [[ "${VERSION_ID}" == "16.04" ]] ; then
    apt -y install python-software-properties  binutils-gold
fi

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
if [[ "${VERSION_ID}" == "18.04" ]] ; then
    cat << EOF > /etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic main
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-6.0 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-6.0 main
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-7 main
EOF
elif [[ "${VERSION_ID}" == "16.04" ]] ; then
    cat << EOF > /etc/apt/sources.list.d/llvm.list
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial main
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main
EOF
fi
apt-get -y update

apt -y install  \
    clang-7 libclang-common-7-dev libclang-7-dev libllvm7 lldb-7 llvm-7 \
    llvm-7-dev llvm-7-runtime clang-format-7 python-clang-7 python-lldb-7 \
    liblldb-7-dev lld-7 libfuzzer-7-dev libc++-7-dev
update-alternatives --install \
  /usr/bin/clang clang /usr/bin/clang-7 40 \
  --slave /usr/bin/clang++ clang++ /usr/bin/clang++-7 \
  --slave /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-7 \
  --slave /usr/bin/asan-symbolize asan-symbolize /usr/bin/asan_symbolize-7 \
  --slave /usr/bin/clang-format clang-format /usr/bin/clang-format-7 \
  --slave /usr/bin/lldb lldb /usr/bin/lldb-7 \
  --slave /usr/bin/lldb-server lldb-server /usr/bin/lldb-server-7 \
  --slave /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-7 \
  --slave /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-7 \
  --slave /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-7
update-alternatives --auto clang

apt -y autoremove

cd /tmp
wget https://github.com/linux-test-project/lcov/releases/download/v1.13/lcov-1.13.tar.gz
tar xfvz lcov-1.13.tar.gz
cd lcov-1.13
make install PREFIX=/usr/local
cd ..
rm -r lcov-1.13 lcov-1.13.tar.gz

pip install requests
pip install https://github.com/codecov/codecov-python/archive/master.zip

cd /tmp
OPENSSL_VER=1.1.1
wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz
tar xvf openssl-${OPENSSL_VER}.tar.gz
cd openssl-${OPENSSL_VER}
./config -fPIC --prefix=/usr/local --openssldir=/usr/local/openssl zlib shared -g
make -j$(nproc)
make install
cd ..
rm -f openssl-${OPENSSL_VER}.tar.gz
rm -rf openssl-${OPENSSL_VER}

cd /tmp
wget https://github.com/doxygen/doxygen/archive/Release_1_8_14.tar.gz
tar xvf Release_1_8_14.tar.gz
cd doxygen-Release_1_8_14
mkdir build
cd build
cmake -G "Unix Makefiles" ..
make -j$(nproc)
make install
cd ../..
rm -f Release_1_8_14.tar.gz
rm -rf doxygen-Release_1_8_14

cd /tmp
wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
tar xvf LATEST.tar.gz
cd libsodium-stable
./configure --prefix=/usr/local
make -j$(nproc) && make check
make install
cd ..
rm -f LATEST.tar.gz
rm -rf libsodium-stable

mkdir -p /opt/plantuml
wget -O /opt/plantuml/plantuml.jar http://sourceforge.net/projects/plantuml/files/plantuml.jar/download

set +e
mkdir -p /opt/jenkins
set -e

mkdir -p /opt/local/nih_cache

function build_boost()
{
	local boost_ver=$1
    local do_link=$2
    local boost_path=$(echo "${boost_ver}" | sed -e 's!\.!_!g')
    cd /tmp
    wget https://dl.bintray.com/boostorg/release/${boost_ver}/source/boost_${boost_path}.tar.bz2
    mkdir -p /opt/local
    cd /opt/local
    tar xvf /tmp/boost_${boost_path}.tar.bz2
    if [ "$do_link" = true ] ; then
        ln -s ./boost_${boost_path} boost
    fi
    cd boost_${boost_path}
    ./bootstrap.sh
    ./b2 -j$(nproc)
    ./b2 stage
    cd ..
    rm -f /tmp/boost_${boost_path}.tar.bz2
}

build_boost "1.67.0" true
build_boost "1.68.0" false

cd /tmp
CM_INSTALLER=cmake-3.12.3-Linux-x86_64.sh
CM_VER_DIR=/opt/local/cmake-3.12
wget https://cmake.org/files/v3.12/$CM_INSTALLER
chmod a+x $CM_INSTALLER
mkdir -p $CM_VER_DIR
ln -s $CM_VER_DIR /opt/local/cmake
./$CM_INSTALLER --prefix=$CM_VER_DIR --exclude-subdir
rm -f /tmp/$CM_INSTALLER

