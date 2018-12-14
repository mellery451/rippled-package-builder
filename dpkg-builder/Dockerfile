ARG DIST_TAG=18.04
FROM ubuntu:$DIST_TAG

# install/setup prerequisites:
COPY dpkg-builder/rippled-ubuntu-setup.sh /tmp
RUN chmod a+x /tmp/rippled-ubuntu-setup.sh
RUN /tmp/rippled-ubuntu-setup.sh

# prep files for package building
RUN mkdir -p /opt/rippled_bld/pkg
WORKDIR /opt/rippled_bld/pkg
RUN git clone https://github.com/ripple/rippled.git
RUN git clone https://github.com/ripple/validator-keys-tool.git

COPY dpkg-builder/debian /opt/rippled_bld/pkg/debian/
COPY common/update_sources.sh ./
COPY dpkg-builder/build_dpkg.sh ./

CMD ./build_dpkg.sh
