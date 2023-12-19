#!/usr/bin/env bash

VERSION=$1

apt-get install -y -o Acquire::Retries=10 \
    gcc-$VERSION \
    g++-$VERSION

rm /usr/bin/gcc /usr/bin/g++
ln -s /usr/bin/gcc-$VERSION /usr/bin/gcc
ln -s /usr/bin/g++-$VERSION /usr/bin/g++