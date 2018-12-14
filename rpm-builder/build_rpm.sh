#!/bin/bash

source update_sources.sh

# Build the rpm

IFS='-' read -r RIPPLED_RPM_VERSION RELEASE <<< "$RIPPLED_VERSION"
export RIPPLED_RPM_VERSION

RPM_RELEASE=${RPM_RELEASE-1}

# post-release version
if [ "hf" = "$(echo "$RELEASE" | cut -c -2)" ]; then
  RPM_RELEASE="${RPM_RELEASE}.${RELEASE}"
# pre-release version (-b or -rc)
elif [[ $RELEASE ]]; then
  RPM_RELEASE="0.${RPM_RELEASE}.${RELEASE}"
fi

export RPM_RELEASE

if [[ $RPM_PATCH ]]; then
  RPM_PATCH=".${RPM_PATCH}"
  export RPM_PATCH
fi

tar -zcf ~/rpmbuild/SOURCES/rippled.tar.gz rippled/
tar -zcf ~/rpmbuild/SOURCES/validator-keys.tar.gz validator-keys-tool/

rpmbuild -ba rippled.spec
rc=$?; if [[ $rc != 0 ]]; then
  error "error building rpm"
fi

# Make a tar of the rpm and source rpm
RPM_VERSION_RELEASE=`rpm -qp --qf='%{NAME}-%{VERSION}-%{RELEASE}' ~/rpmbuild/RPMS/x86_64/rippled-[0-9]*.rpm`
tar_file=$RPM_VERSION_RELEASE.tar.gz

tar -zvcf $tar_file -C ~/rpmbuild/RPMS/x86_64/ . -C ~/rpmbuild/SRPMS/ .
cp $tar_file /opt/rippled-rpm/out/

RPM_MD5SUM=`rpm -q --queryformat '%{SIGMD5}\n' ~/rpmbuild/RPMS/x86_64/rippled-[0-9]*.rpm 2> /dev/null`
DBG_MD5SUM=`rpm -q --queryformat '%{SIGMD5}\n' ~/rpmbuild/RPMS/x86_64/rippled-debuginfo*.rpm 2> /dev/null`
DEV_MD5SUM=`rpm -q --queryformat '%{SIGMD5}\n' ~/rpmbuild/RPMS/x86_64/rippled-devel*.rpm 2> /dev/null`
SRC_MD5SUM=`rpm -q --queryformat '%{SIGMD5}\n' ~/rpmbuild/SRPMS/*.rpm 2> /dev/null`

RPM_SHA256="$(sha256sum ~/rpmbuild/RPMS/x86_64/rippled-[0-9]*.rpm | awk '{ print $1}')"
DBG_SHA256="$(sha256sum ~/rpmbuild/RPMS/x86_64/rippled-debuginfo*.rpm | awk '{ print $1}')"
DEV_SHA256="$(sha256sum ~/rpmbuild/RPMS/x86_64/rippled-devel*.rpm | awk '{ print $1}')"
SRC_SHA256="$(sha256sum ~/rpmbuild/SRPMS/*.rpm | awk '{ print $1}')"

echo "rpm_md5sum=$RPM_MD5SUM" > /opt/rippled-rpm/out/build_vars
echo "dbg_md5sum=$DBG_MD5SUM" >> /opt/rippled-rpm/out/build_vars
echo "dev_md5sum=$DEV_MD5SUM" >> /opt/rippled-rpm/out/build_vars
echo "src_md5sum=$SRC_MD5SUM" >> /opt/rippled-rpm/out/build_vars
echo "rpm_sha256=$RPM_SHA256" >> /opt/rippled-rpm/out/build_vars
echo "dbg_sha256=$DBG_SHA256" >> /opt/rippled-rpm/out/build_vars
echo "dev_sha256=$DEV_SHA256" >> /opt/rippled-rpm/out/build_vars
echo "src_sha256=$SRC_SHA256" >> /opt/rippled-rpm/out/build_vars
echo "rippled_version=$RIPPLED_RPM_VERSION" >> /opt/rippled-rpm/out/build_vars
echo "rpm_file_name=$tar_file" >> /opt/rippled-rpm/out/build_vars
echo "rpm_version_release=$RPM_VERSION_RELEASE" >> /opt/rippled-rpm/out/build_vars
