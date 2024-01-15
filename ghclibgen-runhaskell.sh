#!/usr/bin/env bash

set -euxo pipefail

flavors=("ghc-8.8.1")
resolvers=("nightly-2020-01-19") # ghc-8.8.1
                                 # can't ghc-8.6.5, ghc-8.4.4 because cabal < 3.0
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r"
    done
done

flavors=("ghc-8.8.4")
resolvers=("lts-16.31") # ghc-8.8.4
                        # can't ghc-8.6.5, ghc-8.4.4 because cabal < 3.0
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r"
    done
done

flavors=("ghc-8.10.7")
resolvers=("lts-18.28" "lts-16.31") # ghc-8.10.7, ghc-8.8.4
                                    # can't do ghc-8.6.5 since cabal < 3
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

flavors=("ghc-9.2.8")
resolvers=("lts-20.25" "lts-19.33" "lts-18.28") # ghc-9.2.8, ghc-9.0.2, ghc-8.10.7
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-9.4.8") # fails to build hadrian w/"nightly-2023-05-07"
resolvers=( "lts-20.25" "lts-19.20") # ghc-9.2.8, ghc-9.0.2
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" # --no-checkout
    done
done

flavors=("ghc-9.6.4")
resolvers=("nightly-2023-07-22" "lts-21.0" "lts-20.20") # ghc-9.6.2 ghc-9.4.5, ghc-9.2.7
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" --no-checkout
    done
done

flavors=("ghc-9.8.1")
resolvers=( "lts-22.4" "lts-21.0" ) # ghc-9.6.3 ghc-9.4.5

# neither of these resolvers have semaphore-compat so stack-yaml needs an extra-deps
# extra-deps:
# - semaphore-compat-1.0.0
# for f in "${flavors[@]}"; do
#     for r in "${resolvers[@]}"; do
#         echo "-- "
#         stack runhaskell CI.hs --stack-yaml stack.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack.yaml --resolver "$r" --no-checkout
#     done
# done
