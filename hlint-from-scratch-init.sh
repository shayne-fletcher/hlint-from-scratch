#!/usr/bin/env bash

set -euo pipefail

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

if [[ ! -d "$repo_dir" ]]; then
    mkdir -p "$repo_dir"
fi

pushd "$repo_dir"

if false; then
  if [ ! -d "ghc" ]; then
      git clone https://gitlab.haskell.org/ghc/ghc.git --recursive
      pushd "ghc"
      git fetch origin --tags
      popd
   fi
else
   # update checkout to origin/master HEAD. not used right now.
   if false; then
       echo "updating ghc..."
       pushd "ghc"
       git clean -xdf && \
           git submodule foreach git clean -xdf && \
           git submodule foreach git checkout . && \
           git checkout .
       git fetch origin
       git merge origin/master
       git submodule update --init --recursive
       popd
   else
       echo "skip clone ghc.."
   fi
fi

if false; then
  if [ ! -d "stack" ]; then
      git clone https://github.com/commercialhaskell/stack.git
      pushd "stack"
      git fetch origin --tags
      popd
  fi
else
    echo "skip clone stack..."
fi

if [ ! -d "ghc-lib" ]; then
    git clone https://github.com/shayne-fletcher/ghc-lib.git
    pushd "ghc-lib"
    git fetch origin --tags
    git clone https://gitlab.haskell.org/ghc/ghc.git --recursive
    pushd "ghc"
    git fetch origin --tags
    popd
    popd
else
    echo "skip clone ghc-lib..."
fi

if [ ! -d "ghc-lib-parser-ex" ]; then
    git clone https://github.com/shayne-fletcher/ghc-lib-parser-ex.git
    pushd "ghc-lib-parser-ex"
    git fetch origin --tags
    popd
else
    echo "skip clone ghc-lib-parser-ex..."
fi
if [ ! -d "hlint" ]; then
    git clone https://github.com/ndmitchell/hlint.git
    pushd "hlint"
    git fetch origin --tags
    popd
else
    echo "skip clone hlint..."
fi
