#!/usr/bin/env bash

set -euxo pipefail

prog=$(basename "$0")
opt_args="
ARG is a directory for git repo clones e.g. --repo-dir=$HOME/project
OPTS is a quoted string with contents e.g: \"\""
usage="usage: $prog ARG OPTS""
$opt_args"

repo_dir=""
while [ "$#" -gt 0 ]; do
    if [[ "$1" == "--help" ]]; then
        echo "$usage" && exit 0
    elif [[ "$1" =~ --repo-dir=(.*)$ ]]; then
      repo_dir="${BASH_REMATCH[1]}"
    else
        printf "unexpected argument\n%s" "$usage\n" && exit 1
    fi
    shift
done

if [[ -z "$repo_dir" ]]; then
    repo_dir="$(realpath "$HOME/project")"
fi

pushd "$repo_dir"

if [ ! -d "ghc-lib" ]; then
    echo "missing dir 'ghc-lib'"
    exit 1
fi

pushd "ghc-lib"

# these are hlint buildable
head=""
flavors=("$head" "ghc-master" "ghc-9.6.1" "ghc-9.4.4")
resolvers=("ghc-9.4.4")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        hlint-from-scratch --ghc-flavor="$f" --cabal-with-ghc="$r" --no-checkout --no-haddock --stack-yaml=stack-exact.yaml --resolver="$r"
        git checkout CI.hs # restore "Last tested gitlab.haskell.org/ghc/ghc.git " sha
    done
done

# these are hlint buildable
flavors=("ghc-9.6.1" "ghc-9.4.4") # these are not: "ghc-9.2.x"
resolvers=("ghc-9.2.6")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        hlint-from-scratch --ghc-flavor="$f" --cabal-with-ghc="$r" --no-checkout --no-builds --no-haddock --stack-yaml=stack-exact.yaml --resolver="$r"
        git checkout CI.hs # restore "Last tested gitlab.haskell.org/ghc/ghc.git " sha
    done
done

# this is hlint buildable
flavors=("ghc-9.4.4") # these are not: "ghc-9.2.6" "ghc-9.0.2"
resolvers=("ghc-9.0.2")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        hlint-from-scratch --ghc-flavor="$f" --cabal-with-ghc="$r" --no-checkout --no-haddock --stack-yaml=stack-exact.yaml --resolver="$r"
        git checkout CI.hs # restore "Last tested gitlab.haskell.org/ghc/ghc.git " sha
    done
done

# don't run this script again until there's a new commit upstream
git checkout .
PATH=/Users/shayne/project/hlint-from-scratch:"$PATH" hlint-from-scratch --ghc-flavor="" --stack-yaml=stack-exact.yaml --resolver=ghc-9.4.4 --no-checkout --no-builds --no-cabal
git checkout examples ghc-lib-gen.cabal

popd
popd
