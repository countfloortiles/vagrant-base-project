#!/usr/bin/env bash
echo "\nInstalling node.js.\n"

# Install dependencies.
apt-get install make
apt-get install g++

mkdir temp
cd temp
git clone https://github.com/joyent/node.git
cd node
./configure
make
make install
