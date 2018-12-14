#!/bin/bash

function error {
  echo $1
  exit 1
}

GIT_REMOTE=${GIT_REMOTE-origin}

if [ -z ${GIT_COMMIT+x} ]; then
  GIT_BRANCH=${GIT_REMOTE}/${GIT_BRANCH-develop}
else
  GIT_BRANCH=$GIT_COMMIT
fi

cd rippled

if [ "$GIT_REMOTE" != "origin" ]; then
  git remote add $GIT_REMOTE https://github.com/$GIT_REMOTE/rippled.git
fi

git fetch $GIT_REMOTE
rc=$?; if [[ $rc != 0 ]]; then
  error "error fetching $GIT_REMOTE"
fi

# fetch again, including remotes...but ok if this fails for some reason
git fetch $GIT_REMOTE "+refs/pull/*/head:refs/remotes/origin/pr/*"

git checkout $GIT_BRANCH
rc=$?; if [[ $rc != 0 ]]; then
  error "error checking out $GIT_BRANCH"
fi
git pull

# Import rippled dev public keys
if [ -e /opt/rippled-rpm/public-keys.txt ]; then
  gpg --import /opt/rippled-rpm/public-keys.txt

  # Verify git commit signature
  COMMIT_SIGNER=`git verify-commit HEAD 2>&1 >/dev/null | grep 'Good signature from' | grep -oP '\"\K[^"]+'`
  if [ -z "$COMMIT_SIGNER" ]; then
    error "rippled git commit signature verification failed"
  fi
fi

export RIPPLED_VERSION=$(egrep -i -o "\b(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9a-z\-]+(\.[0-9a-z\-]+)*)?(\+[0-9a-z\-]+(\.[0-9a-z\-]+)*)?\b" src/ripple/protocol/impl/BuildInfo.cpp)

cd ../validator-keys-tool
git fetch origin
git checkout origin/master

if [ -e /opt/rippled-rpm/public-keys.txt ]; then
  # Verify git commit signature
  COMMIT_SIGNER=`git verify-commit HEAD 2>&1 >/dev/null | grep 'Good signature from' | grep -oP '\"\K[^"]+'`
  if [ -z "$COMMIT_SIGNER" ]; then
    error "validator-keys git commit signature verification failed"
  fi
fi

git submodule update --init --recursive
cd ..

