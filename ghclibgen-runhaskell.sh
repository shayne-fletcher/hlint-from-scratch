#!/usr/bin/env bash

# ghclibgen build/test flavor/resolver pairs where flavors:
# ["ghc-9.0.2, .., "ghc-master""), resolvers: ["ghc-9.0.2", ..
# "ghc-9.6.1")

flavors=("ghc-master" "ghc-9.6.1")
resolvers=("ghc-9.4.4") # ghc-9.6.1 hasn't been released yet
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done

flavors=("ghc-9.4.4")
resolvers=("ghc-9.4.4" "ghc-9.2.6")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done

flavors=("ghc-9.2.6")
resolvers=("ghc-9.2.6" "ghc-9.0.2")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done

flavors=("ghc-9.0.2")
resolvers=("ghc-9.0.2")

for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        stack runhaskell CI.hs --stack-yaml stack-exact.yaml --resolver "$r" --package extra --package optparse-applicative -- --ghc-flavor "$f" --stack-yaml stack-exact.yaml --resolver "$r" --no-checkout
    done
done
