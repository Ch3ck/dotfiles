#!/usr/bin/env bash

## rust cargo
# shellcheck source=/dev/null
source ~/.cargo/env

## Go env vars
export GO111MODULE=on
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH"
