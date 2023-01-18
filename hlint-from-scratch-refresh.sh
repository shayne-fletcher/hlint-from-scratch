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
else
    :
fi

ds=("ghc-lib-parser-ex" "hlint")
branches=("ghc-9.6.1" "ghc-next")
for d in "${ds[@]}"; do
    if [ ! -d "$d" ]; then
        echo "missing dir $d"
        exit 1
    else
        pushd "$d"

        git checkout master
        git checkout .
        git fetch origin --tags

        for b in "${branches[@]}"; do
            if git show-ref --quiet refs/heads/"$b"; then
                git branch -D "$b"
            fi
            git checkout -t origin/"$b"
        done

        popd
    fi
done
