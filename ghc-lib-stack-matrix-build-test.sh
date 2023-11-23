#!/usr/bin/env bash

set -euo pipefail

flavors=("ghc-master" "ghc-9.8.1")
resolvers=("ghc-9.8.1" "ghc-9.6.3" "ghc-9.4.8")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative CI.hs -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done

flavors=("ghc-9.6.3" "ghc-9.4.8")
resolvers=("ghc-9.4.8" "ghc-9.2.8")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative CI.hs -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done
