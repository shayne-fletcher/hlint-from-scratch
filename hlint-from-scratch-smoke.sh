#!/usr/bin/env bash

set -euxo pipefail

head="ghc-master"

GHCLIB_AZURE= PATH=~/project/hlint-from-scratch:$PATH  hlint-from-scratch --ghc-flavor="$head" --no-checkout --no-builds --no-cabal --stack-yaml=stack-exact.yaml --resolver=ghc-9.6.2

GHCLIB_AZURE= PATH=~/project/hlint-from-scratch:$PATH  hlint-from-scratch --ghc-flavor="ghc-9.8.1" --no-checkout --no-builds --no-cabal --stack-yaml=stack-exact.yaml --resolver=ghc-9.6.2
