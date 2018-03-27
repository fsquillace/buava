#!/bin/sh
set -ex

brew update
brew install bash zsh
# Coreutils and git should be already installed on OSX 7.3+ images:
#brew install coreutils git

./tests/test-utils/install-fish.sh "$TRAVIS_FISH_VERSION"
