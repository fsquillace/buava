#!/bin/sh

set -ex

sudo apt-get -qq update
sudo apt-get install -y zsh bash git

./tests/test-utils/install-fish.sh "$TRAVIS_FISH_VERSION"
