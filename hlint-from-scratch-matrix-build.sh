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

flavors=("" "ghc-master" "ghc-9.6.1")
resolvers=("ghc-9.4.4" "ghc-9.2.5")
for f in "${flavors[@]}"; do
    for r in "${resolvers[@]}"; do
        echo "-- "
        hlint-from-scratch --ghc-flavor="$f" --no-checkout --no-builds --no-haddock --stack-yaml=stack-exact.yaml --resolver="$r"
        if false;  then
          git checkout CI.hs # restore last tested shas
        fi
    done
done

popd
popd
