#!/bin/bash

source update_sources.sh

# Build the dpkg

#dpkg uses - as separator, so we need to change our -bN versions to tilde
RIPPLED_DPKG_VER=$(echo "${RIPPLED_VERSION}" | sed 's!-!~!g')

cd rippled
git archive --format tar.gz --prefix rippled-${RIPPLED_DPKG_VER}/ -o ../rippled-${RIPPLED_DPKG_VER}.tar.gz ${GIT_BRANCH}
cd ..
# dpkg debmake would normally create this link, but we do it manually
ln -s ./rippled-${RIPPLED_DPKG_VER}.tar.gz rippled_${RIPPLED_DPKG_VER}.orig.tar.gz
tar xvf rippled-${RIPPLED_DPKG_VER}.tar.gz
cd rippled-${RIPPLED_DPKG_VER}
cp -pr ../debian .

# dpkg requires a changelog. We don't currently maintain
# a useable one, so let's just fake it with our current version
NOWSTR=$(TZ=UTC date -R)
cat << CHANGELOG > ./debian/changelog
rippled (${RIPPLED_DPKG_VER}-1) unstable; urgency=low

  * see RELEASENOTES

 -- Ripple Inc <support@ripple.com>  ${NOWSTR}
CHANGELOG

debuild -F -us -uc
rc=$?; if [[ $rc != 0 ]]; then
  error "error building rpm"
fi
cd ..
ls -latr

# TODO..somehow add validator-keys-tool sources ?

# copy artifacts
cp rippled-dev_${RIPPLED_DPKG_VER}-1_amd64.deb /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1_amd64.deb /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1.dsc /opt/rippled_bld/out
cp rippled-dbgsym_${RIPPLED_DPKG_VER}-1_amd64.ddeb /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1_amd64.buildinfo /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1_amd64.changes /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1_amd64.build /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}.orig.tar.gz /opt/rippled_bld/out
cp rippled_${RIPPLED_DPKG_VER}-1.debian.tar.xz /opt/rippled_bld/out

cat rippled_${RIPPLED_DPKG_VER}-1_amd64.changes
awk '/Checksums-Sha256:/{hit=1;next}/Files:/{hit=0}hit' rippled_${RIPPLED_DPKG_VER}-1_amd64.changes | \
    sed -E 's!^[[:space:]]+!!' > shasums
DEB_SHA256=$(cat shasums | grep "rippled_${RIPPLED_DPKG_VER}-1_amd64.deb" | cut -d " " -f 1)
DBG_SHA256=$(cat shasums | grep "rippled-dbgsym_${RIPPLED_DPKG_VER}-1_amd64.ddeb" | cut -d " " -f 1)
DEV_SHA256=$(cat shasums | grep "rippled-dev_${RIPPLED_DPKG_VER}-1_amd64.deb" | cut -d " " -f 1)
SRC_SHA256=$(cat shasums | grep "rippled_${RIPPLED_DPKG_VER}.orig.tar.gz" | cut -d " " -f 1)
echo "deb_sha256=${DEB_SHA256}" >> /opt/rippled_bld/out/build_vars
echo "dbg_sha256=${DBG_SHA256}" >> /opt/rippled_bld/out/build_vars
echo "dev_sha256=${DEV_SHA256}" >> /opt/rippled_bld/out/build_vars
echo "src_sha256=${SRC_SHA256}" >> /opt/rippled_bld/out/build_vars
echo "rippled_version=${RIPPLED_VERSION}" >> /opt/rippled_bld/out/build_vars
echo "dpkg_version=${RIPPLED_DPKG_VER}" >> /opt/rippled_bld/out/build_vars
