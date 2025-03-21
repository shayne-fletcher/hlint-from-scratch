#!/usr/bin/env bash

# Build a cabal project composed from a set of .tar.gz sdists of
# ghc-lib-parser, ghc-lib, ghc-lib-parser-ex and hlint. Choice of
# ghc-lib version & build compiler are provided as arguments.
#
# This script relies on
#  -  $HOME/$ghc_version/bin
#  -  /Users/shayne/.cabal/bin being in PATH

set -exo pipefail

prog=$(basename "$0")
opt_args="
opts:
    --ghc-version=ARG
    --version-tag=ARG
    --ghc-lib-dir=ARG
    --ghc-lib-parser-ex-dir=ARG
    --hlint-dir=ARG
    --build-dir=ARG
    --with-haddock
    --no-threaded-rts
"
usage="usage: $prog ARGS"

ghc_version="ghc-$(echo -n "$(ghc --numeric-version)")"
version_tag=""
ghc_lib_dir=""
ghc_lib_parser_ex_dir=""
hlint_dir=""
build_dir=""
with_haddock=false
no_threaded_rts=false

while [ $# -gt 0 ]; do
    # The way this script is called, $1 can be defined but empty.
    if [ -z "$1" ]; then
        :
    elif [ "$1" = "--help" ]; then
        echo "$usage" && exit 0
    elif [[ "$1" =~ --ghc-version=([^[:space:]]+) ]]; then
        ghc_version="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --version-tag=([^[:space:]]+) ]]; then
        version_tag="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --ghc-lib-dir=([^[:space:]]+) ]]; then
        ghc_lib_dir="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --ghc-lib-parser-ex-dir=([^[:space:]]+) ]]; then
        ghc_lib_parser_ex_dir="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --hlint-dir=([^[:space:]]*)+ ]]; then
        hlint_dir="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --build-dir=([^[:space:]]+) ]]; then
        build_dir="${BASH_REMATCH[1]}"
    elif [ "$1" = --with-haddock ]; then
        with_haddock=true
    elif [ "$1" = --no-threaded-rts ]; then
        no_threaded_rts=true
    else
        echo "unexpected argument \"$1\""
        echo "$usage" && exit 1
    fi
    shift
done

[ -z "$ghc_version" ] && \
    echo "Missing ghc-version" && echo "$usage" && exit 1
[ -z "$version_tag" ] && \
    echo "Missing version-tag" && echo "$usage" && exit 1
[ -z "$ghc_lib_dir" ] && \
    ghc_lib_dir="$HOME/project/sf-ghc-lib" && \
    echo "Missing 'ghc-lib-dir': defaulting to $ghc_lib_dir"
[ ! -e  "$ghc_lib_dir" ] && { echo "\"$ghc_lib_dir\" does not exist" && exit 1;  }
[ -z "$ghc_lib_parser_ex_dir" ] && \
    ghc_lib_parser_ex_dir="$HOME/project/ghc-lib-parser-ex" && \
    echo "Missing 'ghc-lib-parser-ex-dir': defaulting to $ghc_lib_parser_ex_dir"
[ ! -e  "$ghc_lib_parser_ex_dir" ] && { echo "\"$ghc_lib_parser_ex_dir\" does not exist" && exit 1;  }
[ -z "$hlint_dir" ] && \
    hlint_dir="$HOME/project/hlint" && \
    echo "Missing 'hlint-dir': defaulting to $hlint_dir"
[ ! -e  "$hlint_dir" ] && { echo "\"$hlint_dir\" does not exist" && exit 1;  }
[ -z "$build_dir" ] && \
    build_dir="$HOME/tmp/ghc-lib/$version_tag" && \
    echo "Missing 'build-dir': defaulting to $build_dir"

set -u

if [ -d "$HOME/$ghc_version" ]; then
  PATH="$HOME/$ghc_version/bin:$PATH"
  export PATH
fi

echo "cabal-install: $(which cabal)"
echo "cabal-install version: $(cabal -V)"
echo "ghc: $(which ghc)"
echo "ghc version : $(ghc -V)"

echo "cabal build starting up: getting packages"

build_dir_for_this_ghc="$build_dir/$ghc_version"
mkdir -p "$build_dir_for_this_ghc"
cd "$build_dir_for_this_ghc"
packages=(                                                      \
 "$ghc_lib_dir/ghc-lib-gen-$version_tag.tar.gz"                 \
 "$ghc_lib_dir/ghc-lib-parser-$version_tag.tar.gz"              \
 "$ghc_lib_dir/ghc-lib-$version_tag.tar.gz"                     \
 "$ghc_lib_dir/ghc-lib-test-utils-$version_tag.tar.gz"          \
 "$ghc_lib_dir/ghc-lib-test-mini-hlint-$version_tag.tar.gz"     \
 "$ghc_lib_dir/ghc-lib-test-mini-compile-$version_tag.tar.gz"   \
 "$ghc_lib_parser_ex_dir/ghc-lib-parser-ex-$version_tag.tar.gz" \
 "$hlint_dir/hlint-$version_tag.tar.gz"                         \
)
set +e # remember to remove this later
for f in "${packages[@]}"; do
  tar xvf "$f"
  base=$(basename "$f")
  (cd "${base%.tar.gz}" && cabal check)
done

# ../.. is the parent of $version_tag/$ghc_version i.e. ~/tmp/ghc-lib
tar_artifact="hlint-$version_tag.tar"
zipped_tar_artifact="$tar_artifact.gz"
rm -rf "dist-newstyle"
(cd ../.. && rm -f "$tar_artifact" "$zipped_tar_artifact" && rm -rf "hlint-$version_tag")
(cd ../.. && mkdir -p "hlint-$version_tag" && cd "hlint-$version_tag" && cp -R "$build_dir_for_this_ghc"/* .)
(cd ../../ && tar cvf "$tar_artifact" "hlint-$version_tag" && rm -rf "hlint-$version_tag")
(cd ../.. && gzip "$tar_artifact" && rm "$tar_artifact")

set -e

haddock=""
if [ "$with_haddock" ]; then
  DOLLAR="$"
  pkg="pkg"
  # shellcheck disable=SC2154
  haddock="haddock-all: true
haddock-hyperlink-source: true
haddock-executables: true
haddock-html-location: http://hackage.haskell.org/packages/archive/$DOLLAR$pkg/latest/doc/html
"
fi

threaded_rts="+threaded-rts"
if "$no_threaded_rts"; then
  threaded_rts="-threaded-rts"
fi

allow_newer=""
extra_constraints=""
# if [ "$ghc_version" == "ghc-9.10.1" ]; then
if false; then
  allow_newer="allow-newer: all" # "allow-newer: ghc-lib:hpc"
#   extra_constraints="th-abstraction==0.6.0.0, text==2.0.1, "
fi
# Requires cabal-instal >= 3.8.1.0
# (reference https://cabal.readthedocs.io/en/3.8/index.html)
constraints="constraints: $extra_constraints hlint +ghc-lib, ghc-lib-parser-ex -auto -no-ghc-lib, ghc-lib $threaded_rts, ghc-lib-parser $threaded_rts"

cat > cabal.project<<EOF
packages: */*.cabal
$allow_newer
$constraints
$haddock
EOF

# packages: */*.cabal
# $allow_newer
# source-repository-package
#   type: git
#   location: https://github.com/shayne-fletcher/text-short.git
#   tag: 0a725f9ce82936629c636bc530d04816cf2162cb
# $constraints
# $haddock
# EOF

cat cabal.project

# clean
cabal new-clean

# cabal new-build all
flags="--ghc-option=-j"
cmd="cabal new-build all $flags"
ffi_inc_path=""
if [ $(uname) == 'Darwin' ]; then
  ffi_inc_path="C_INCLUDE_PATH=$(xcrun --show-sdk-path)/usr/include/ffi"
fi
ghc_version_number=$(ghc -V | tail -c 6)
if [[ "$ghc_version_number" == "9.2.2" ]]; then
    eval "$ffi_inc_path" "$cmd"
else
    eval "$cmd"
fi

# cabal new-haddock all
if "$with_haddock"; then
  eval "cabal" "haddock" "all"
fi

cabal_project="$build_dir_for_this_ghc"/cabal.project
echo -n > "$build_dir_for_this_ghc"/ghc-lib-test-mini-hlint "cabal -v0 run exe:ghc-lib-test-mini-hlint --project-dir .. --  "
echo -n > "$build_dir_for_this_ghc"/ghc-lib-test-mini-compile "cabal -v0 run exe:ghc-lib-test-mini-compile --project-dir .. --  "
(cd ghc-lib-test-mini-hlint-"$version_tag" && eval 'cabal' 'test' '--project-dir' '..' '--test-show-details' 'direct' '--test-options="--color always --test-command ../ghc-lib-test-mini-hlint"')
# (cd ghc-lib-test-mini-compile-"$version_tag" && eval 'cabal' 'test' '--project-dir' '..' '--test-show-details' 'direct' '--test-options="--color always --test-command ../ghc-lib-test-mini-compile"')
(cd ghc-lib-parser-ex-"$version_tag" && eval 'cabal' 'test' '--project-dir' '..' '--test-show-details' 'direct' '--test-options="--color always"')
(cd hlint-"$version_tag" && eval 'cabal' 'run' 'exe:hlint' '--project-dir' '..' '--' '--test')

exit 0
