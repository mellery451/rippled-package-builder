FROM fedora:27
RUN mkdir /opt/rippled-rpm
WORKDIR /opt/rippled-rpm

RUN yum install -y protobuf-static gcc-c++ libstdc++-static git zlib-static cmake rpm-build gnupg wget which coreutils krb5-devel perl-interpreter sed zlib-devel lksctp-tools-devel

RUN wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz && \
    tar -xzf openssl-1.1.0h.tar.gz && \
    cd openssl-1.1.0h && \
    ./Configure \
        --prefix=/usr/local --openssldir=/usr/local/etc/pki/tls \
        enable-ec_nistp_64_gcc_128 \
        zlib enable-camellia enable-seed enable-rfc3779 enable-sctp \
        enable-cms enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method \
        enable-weak-ssl-ciphers \
        no-mdc2 no-ec2m \
        shared linux-x86_64 -g3 -ggdb2 && \
    make -j2 && make install && \
    cd .. && \
    rm openssl-1.1.0h.tar.gz && \
    rm -r openssl-1.1.0h

RUN wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz && \
    tar -xzf boost_1_67_0.tar.gz && \
    cd boost_1_67_0 && \
    ./bootstrap.sh && \
    ./b2 link=static -j2 install && \
    cd .. && \
    rm boost_1_67_0.tar.gz && \
    rm -r boost_1_67_0

RUN mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

RUN git clone https://github.com/ripple/rippled.git

RUN git clone https://github.com/ripple/validator-keys-tool.git

COPY rippled.spec ./
COPY rippled.service /root/rpmbuild/SOURCES/
COPY 50-rippled.preset /root/rpmbuild/SOURCES/
COPY update-rippled.sh /root/rpmbuild/SOURCES/
COPY nofile_limit.conf /root/rpmbuild/SOURCES/

COPY build_rpm.sh ./
CMD ./build_rpm.sh
