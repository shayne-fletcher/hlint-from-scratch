#!/usr/bin/env bash

set -euxo pipefail

flavors=("ghc-9.6.1")
resolvers=("nightly-2023-05-07" "lts-20.20") # ghc-9.4.5, ghc-9.2.7
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" --no-checkout
    done
done


flavors=("ghc-9.4.5") # fails to build hadrian w/"nightly-2023-05-07"
resolvers=( "lts-20.20" "lts-19.20") # ghc-9.4.5, ghc-9.2.7, ghc-9.0.2
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-9.2.7")
resolvers=("lts-20.20" "lts-19.33" "lts-18.28") # ghc-9.2.7, ghc-9.0.2, ghc-8.10.7
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-9.0.2")
resolvers=("lts-19.33" "lts-18.28" "lts-16.31") # ghc-9.0.2, ghc-8.10.7, ghc-8.8.4
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-8.10.7")
resolvers=("lts-18.28" "lts-16.31" "lts-14.27") # ghc-8.10.7, ghc-8.8.4, ghc-8.6.5
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-8.8.4")
resolvers=("lts-16.31" "lts-14.27") # ghc-8.8.4 ghc-8.6.5
                                     # can't ghc-8.4.4 because cabal < 2.4
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r"
    done
done

flavors=("ghc-8.8.1")
resolvers=("nightly-2020-01-19" "lts-14.27") # ghc-8.8.1, ghc-8.6.5
                                             # can't ghc-8.4.4 because cabal < 2.4
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r"
    done
done
