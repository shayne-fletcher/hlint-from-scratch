#!/usr/bin/env bash

# Build and test ghc-lib at HEAD or the given flavor.
#
# - Never run before?
#  - `hlint-from-scratch --init=/path/to/repo-dir`
#    - this will clone ghc, stack, ghc-lib, ghc-lib-parser-ex and
#      hlint into the given path (no use is made of ghc at this time)
#    - thereafter pass (in `opts`) `--repo-dir=/path/to/repo-dir` to
#      `hlint-from-scratch` (default if omitted:`$HOME/project`)

# - Full
#   - `hlint-from-scratch --ghc-flavor=""`, the quickest though is
# - Quickest
#   - `hlint-from-scratch --ghc-flavor="" "--no-checkout --no-builds --no-cabal --no-haddock`

set -eo pipefail

prog=$(basename "$0")
args="
  --help
    Print a usage message and exit.

  --init ARG
    Create a directory of git clones and exit.

  --ghc-flavor=ARG
    Select a specific ghc-flavor. Default's to GHC's HEAD.

  --repo-dir=ARG
    A directory of git clones. Defaults to $HOME/project.

  --stack-yaml=ARG
    Stack configuration file.

  --resolver=ARG
    Stack resolver.

  --no-checkout
    Reuse an existing GHC clone in ghc-lib-parser.

  --no-builds
    Don't build & test ghc-lib packages and examples.

  --no-cabal
    Skip building the hlint stack as a cabal project.

  --cabal-with-ghc
    Provide a ghc version for cabal builds e.g. ghc-9.2.5

  --no-haddock
    Disable generating haddocks (only has meaning if --no-cabal is not provided).

  --no-threaded-rts
    Disable passing -DTHREADED_RTS to the C toolchain when building ghc-lib-parser & ghc-lib.
"
usage="usage: $prog $args"

GHC_FLAVOR=""
no_builds=""
no_cabal=""
cabal_with_ghc="ghc-9.4.4"
stack_yaml=""
stack_yaml_flag=""
resolver=""
resolver_flag=""
repo_dir="$HOME/project"
with_haddock_flag="--with-hadock"
no_threaded_rts=false
no_threaded_rts_flag=""
no_checkout_flag=""

while [ $# -gt 0 ]; do
    if [ "$1" = "--help" ]; then
        echo "$usage" && exit 0
    elif [[ "$1" =~ --ghc-flavor=([^[:space:]]*) ]]; then
        GHC_FLAVOR="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --init=([^[:space:]]+) ]]; then
        init_arg="${BASH_REMATCH[1]}"
        hlint-from-scratch-init --repo-dir="$init_arg"
        echo "repo-dir \"$repo_dir\" initialized"
        echo "next: hlint-from-scratch --ghc-flavor=... ... --repo-dir=$repo_dir"
        exit 0
    elif [[ "$1" =~ --repo-dir=([^[:space:]]+) ]]; then
        repo_dir="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --stack-yaml=([^[:space:]]+) ]]; then
        stack_yaml="${BASH_REMATCH[1]}"
        stack_yaml_flag="--stack-yaml $stack_yaml"
    elif [[ "$1" =~ --resolver=([^[:space:]]+) ]]; then
        resolver="${BASH_REMATCH[1]}"
        resolver_flag="--resolver $resolver"
    elif [[ "$1" =~ --cabal-with-ghc=([^[:space:]]+) ]]; then
        cabal_with_ghc="${BASH_REMATCH[1]}"
    elif [ "$1" = "--no-checkout" ]; then
        no_checkout_flag="--no-checkout"
        echo "cloning ghc skipped."
    elif [ "$1" = "--no-builds" ]; then
        no_builds="--no-builds"
        echo "ghc-lib package & examples building skipped."
    elif [ "$1" = "--no-cabal" ]; then
        no_cabal="--no-cabal"
        echo "hlint stack as a cabal.project building skipped."
    elif [ "$1" = "--no-haddock" ]; then
        with_haddock_flag=""
        echo "generation haddocks skipped."
    elif [ "$1" = "--no-threaded-rts" ]; then
        no_threaded_rts=true
        no_threaded_rts_flag="--no-threaded-rts"
        echo "-DTHREADED_RTS will not be passed to the C toolchain building ghc-lib-parser & ghc-lib."
    else
        echo "unexpected argument \"$1\""
        echo "$usage" && exit 1
    fi
    shift
done

cabal_with_ghc_flag="--ghc-version=$cabal_with_ghc"

threaded_rts="true"
if "$no_threaded_rts"; then
  threaded_rts="false"
fi

set -u

echo "ghc-flavor: $GHC_FLAVOR"
echo "stack-yaml: $stack_yaml"
echo "stack-yaml flag: $stack_yaml_flag"
echo "resolver: $resolver"
echo "resolver flag: $resolver_flag"
echo "repo-dir: $repo_dir"
echo "no-builds: $no_builds"
echo "no-cabal: $no_cabal"
echo "cabal-with-ghc-flag: $cabal_with_ghc_flag"
echo "with-haddock flag: $with_haddock_flag"
echo "no-threaded-rts: $no_threaded_rts"
echo "no-threaded-rts-flag: $no_threaded_rts_flag"
echo "threaded-rts: \"$threaded_rts\""

packages="--package extra --package optparse-applicative"
runhaskell="stack runhaskell $packages"
DOLLAR="$"
locals="locals"
everything="everything"

# If there's a new release, let's have it.
if true; then
  # cd "$repo_dir/stack"
  # git fetch origin && git merge origin/master
  # stack install
  :
else
  stack upgrade # Upgrade to the latest official
fi

cd "$repo_dir"/ghc-lib

if ! [[ -f ./ghc-lib-gen.cabal ]]; then
    echo "Missing 'ghc-lib-gen.cabal'."
    echo "This script should be executed from a ghc-lib checkout directory."
    exit 1
fi

if ! [[ -d ./ghc ]]; then
    echo "There is no ghc checkout here to update."
    echo "Building with ghc-flavor 'ghc-master' to get started."
    eval "$runhaskell $stack_yaml_flag $resolver_flag CI.hs -- $stack_yaml_flag $resolver_flag --ghc-flavor ghc-master"
    echo "Now restarting build at the latest GHC commit."
fi

# It's common for the git fetch step to report errors of the form
# "fatal: remote error: upload-pack: not our ref SHA culminating with
# "Errors during submodule fetch:..." and exit with a non-zero code.
# The --recurse-submodules=no is an attempt to prevent this.
(cd ghc && git checkout . && \
     git fetch origin --prune --tags --recurse-submodules=no \
)
if [ -z "$GHC_FLAVOR" ]; then
  # Get the latest commit SHA.
  HEAD=$(cd ghc && git log origin/master -n 1 | head -n 1 | awk '{ print $2 }')
  if [ -z "$HEAD" ]; then
      echo "\$HEAD is empty. Trying over." && hlint-from-scratch
  fi
  echo "HEAD: $HEAD"

  # Get the latest on ghc-9.6 too.
  GHC_961=$(cd ghc && git log origin/ghc-9.6 -n 1 | head -n 1 | awk '{ print $2 }')

  echo "master: $HEAD"
  echo "ghc-9.6: $GHC_961"

  current_ghc961=""
  if [ -e "ghc-9.6.1-last-tested-at" ]; then
    current_ghc961="$(cat ghc-9.6.1-last-tested-at)"
    if [[ "$current_ghc961" == "$GHC_961" ]]; then
      echo "The current ghc-9.6 \"tested at\" SHA ("$current_ghc961") hasn't changed"
    else
      echo "-- "
      echo "There have been changes on the 9.6 branch"
      # $GHC_961 is new. Summarize the new commits.
      (cd ghc && PAGER=cat git show "$current_ghc961".."$GHC_961" --compact-summary)
      echo "-- "
      fi
  else
      current_ghc961="$GHC_961"
  fi
  # In any case, update the last tested at ghc-9.6 SHA.
  cat > ghc-9.6.1-last-tested-at <<EOF
$GHC_961
EOF

  # If $HEAD agrees with the "last tested at" SHA in CI.hs stop here.
  current=$(grep "current = .*" CI.hs | grep -o "\".*\"" | cut -d "\"" -f 2)
  echo "CI.hs (last tested at): $current"
  if [[ "$current" == "$HEAD" ]]; then
    echo "The last \"tested at\" SHA (\"$current\") hasn't changed"
    exit 99 # So as to stop e.g. stop 'hlint-from-scratch-matrix-build.sh' too.
  fi

  # $HEAD is new. Summarize the new commits.
  (cd ghc && PAGER=cat git show $current..$HEAD --compact-summary)
   echo "-- "

fi

today=$(date -u +'%Y-%m-%d')
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master" ]]; then
  version="0.""$(date -u +'%Y%m%d')"
else
  flavor=$([[ "$GHC_FLAVOR" =~ (ghc\-)([0-9])\.([0-9])\.([0-9]) ]] && echo "${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}")
  version="$flavor"".""$(date -u +'%Y%m%d')"
fi

# ghc-lib

cmd="$runhaskell $stack_yaml_flag $resolver_flag CI.hs -- $stack_yaml_flag $resolver_flag $no_checkout_flag $no_builds --ghc-flavor "
if [ -z "$GHC_FLAVOR" ]; then
    eval "$cmd" "$HEAD"
else
    eval "$cmd" "$GHC_FLAVOR"
fi
sha_ghc_lib_parser=$(shasum -a 256 "$repo_dir"/ghc-lib/ghc-lib-parser-"$version".tar.gz | awk '{ print $1 }')

if [ -z "$GHC_FLAVOR" ]; then
    # If the above worked out, update CI.hs.
    sed -i '' "s/current = \".*\" -- .*/current = \"$HEAD\" -- $today/g" CI.hs
    # Report.
    grep "current = .*" CI.hs
fi

# ghc-lib-parser-ex

cd ../ghc-lib-parser-ex && git checkout .
branch=$(git rev-parse --abbrev-ref HEAD)

# if the flavor indicates ghc's master branch get on
# ghc-lib-parser-ex's 'ghc-next' branch ...
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master" ]]; then
  if [[ "$branch" != "ghc-next" ]]; then
    echo "Not on ghc-next. Trying 'git checkout ghc-next'"
    git checkout ghc-next
  fi
# if the flavor indicates ghc's 9.6.1 branch get on
# ghc-lib-parser-ex's 'ghc-9.6.1' branch ...
elif [[ "$GHC_FLAVOR" == "ghc-9.6.1" ]]; then
  if [[ "$branch" != "ghc-9.6.1" ]]; then
    echo "Not on ghc-9.6.1. Trying 'git checkout ghc-9.6.1'"
    git checkout ghc-9.6.1
  fi
#... else it's a released flavor, get on branch ghc-lib-parser-ex's
#'master' branch
else
  if [[ "$branch" != "master" ]]; then
      echo "Not on master. Trying 'git checkout master'"
      git checkout master
  fi
fi

# If a resolver hasn't been set, set it now to this.
[[ -z "$resolver" ]] && resolver=nightly-2022-08-04 # ghc-9.2.4

# This an elaborate step to create a config file'stack-head.yaml'.
#
# If a stack-yaml argument was provided, seed its contents from it
# otherwise, assume a curated $resolver and create it from scratch.
if [[ -n "$stack_yaml" ]]; then
  echo "Seeding stack-head.yaml from $stack_yaml"
  # shellcheck disable=SC2002
  cat "$stack_yaml" | \
  # Delete any pre-existing ghc-lib-parser extra dependency.
  sed -e "s;^.*ghc-lib-parser.*$;;g" | \
  sed -e "s;^extra-deps:$;\
# enable ghc-9.6.1 as a build compiler (base-4.18.0)\n\
allow-newer: True\n\
extra-deps:\n\
  # ghc-lib-parser\n\
  - archive: ${repo_dir}/ghc-lib/ghc-lib-parser-${version}.tar.gz\n\
    sha256: \"${sha_ghc_lib_parser}\";\
g" | \
  sed -e "s;^resolver:.*$;resolver: ${resolver};g" > stack-head.yaml
else
  cat > stack-head.yaml <<EOF
resolver: $resolver
extra-deps:
  - archive: ${repo_dir}/ghc-lib/ghc-lib-parser-$version.tar.gz
    sha256: "$sha_ghc_lib_parser"
ghc-options:
    "$DOLLAR$everything": -j
    "$DOLLAR$locals": -ddump-to-file -ddump-hi -Wall -Wno-name-shadowing -Wunused-imports
flags:
 ghc-lib-parser:
   threaded-rts: $threaded_rts
  ghc-lib-parser-ex:
    auto: false
    no-ghc-lib: false
packages:
  - .
EOF
fi

stack_yaml=stack-head.yaml
stack_yaml_flag="--stack-yaml $stack_yaml"
# No need to pass $resolver_flag here, we fixed the resolver in
# 'stack-head.yaml'.
eval "$runhaskell $stack_yaml_flag CI.hs -- $no_builds $stack_yaml_flag --version-tag $version"
sha_ghc_lib_parser_ex=$(shasum -a 256 "$repo_dir"/ghc-lib-parser-ex/ghc-lib-parser-ex-"$version".tar.gz | awk '{ print $1 }')

# Hlint

cd ../hlint && git checkout .
branch=$(git rev-parse --abbrev-ref HEAD)
# if the flavor indicates ghc's master branch get on hlint's
# 'ghc-next' branch ...
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master"
 ]]; then
  if [[ "$branch" != "ghc-next" ]]; then
    echo "Not on ghc-next. Trying 'git checkout ghc-next'"
    git checkout ghc-next
  fi
# if the flavor indicates ghc's 9.6.1 branch get on
# ghc-lib-parser-ex's 'ghc-9.6.1' branch ...
elif [[ "$GHC_FLAVOR" == "ghc-9.6.1" ]]; then
  if [[ "$branch" != "ghc-9.6.1" ]]; then
    echo "Not on ghc-9.6.1. Trying 'git checkout ghc-9.6.1'"
    git checkout ghc-9.6.1
  fi
#... else it's a released flavor, get on branch hlint's 'master'
#branch
else
  if [[ "$branch" != "master" ]]; then
      echo "Not on master. Trying 'git checkout master'"
      git checkout master
  fi
fi

# We're stuck with only curated resolvers for hlint at this time.
resolver=nightly-2023-01-01 # ghc-9.4.4

cat > stack-head.yaml <<EOF
resolver: $resolver
packages:
  - .
extra-deps:
  - archive: $repo_dir/ghc-lib/ghc-lib-parser-$version.tar.gz
    sha256: "$sha_ghc_lib_parser"
  - archive: $repo_dir/ghc-lib-parser-ex/ghc-lib-parser-ex-$version.tar.gz
    sha256: "$sha_ghc_lib_parser_ex"
ghc-options:
    "$DOLLAR$everything": -j
    "$DOLLAR$locals": -ddump-to-file -ddump-hi -Werror=unused-imports -Werror=unused-local-binds -Werror=unused-top-binds -Werror=orphans
flags:
 hlint:
   ghc-lib: true
 ghc-lib-parser:
   threaded-rts: $threaded_rts
 ghc-lib-parser-ex:
   auto: false
   no-ghc-lib: false
# Allow out-of-bounds ghc-lib-parser and ghc-lib-parser-ex.
allow-newer: true
EOF

# phase: hlint: stack build/test
if ! [ "$no_builds" == --no-builds ]; then
  # Again, it would be wrong to pass $resolver_flag here.
  eval "C_INCLUDE_PATH="$(xcrun --show-sdk-path)"/usr/include/ffi" "stack" "$stack_yaml_flag" "build"
  eval "C_INCLUDE_PATH="$(xcrun --show-sdk-path)"/usr/include/ffi" "stack" "$stack_yaml_flag" "run" "--" "--test"
fi

# --
# - phase: test-ghc-9.0.sh
#   (test building the hlint stack as a cabal.project)

if [ "$no_cabal" == --no-cabal ]; then
  echo "hlint as a cabal.project skipped (and now my watch is ended)."
  exit 0
else
  echo "--
  hlint as a cabal.project.
"
fi

# It's so annoying. I just cannot get 'allow-newer' to work in this
# context. Well, never mind; take the approach of constraining the
# bounds exactly. It's kind of more explicitly saying what we mean
# anyway.
sed -i '' "s/^version:.*\$/version:            $version/g" hlint.cabal
sed -i '' "s/^.*ghc-lib-parser ==.*\$/          ghc-lib-parser == $version/g" hlint.cabal
sed -i '' "s/^.*ghc-lib-parser-ex >=.*\$/          ghc-lib-parser-ex == $version/g" hlint.cabal
eval "stack" "$stack_yaml_flag" "sdist" "." "--tar-dir" "."

# - Generate a cabal.project of
#   - ghc-lib, ghc-lib-parser-ex, examples, hlint
#     - (somwhere like ~/tmp/ghc-lib/ghc-lib-9.4.3.20221104/ghc-9.4.1/cabal.project
# - and `cabal new-build all`.
# - Maybe produce haddocks too
#   - Depending on the contents of `$with_haddock_flag`. Also,
# - Run ghc-lib-test-mini-hlint, ghc-lib-test-mini-compile and the
#   hlint test suite.
tmp_dir="$HOME/tmp"
mkdir -p "$tmp_dir"
(cd "$HOME"/tmp && hlint-from-scratch-cabal-build-test.sh  \
     "$cabal_with_ghc_flag"                                \
     --version-tag="$version"                              \
     --ghc-lib-dir="$repo_dir/ghc-lib"                     \
     --ghc-lib-parser-ex-dir="$repo_dir/ghc-lib-parser-ex" \
     --hlint-dir="$repo_dir/hlint"                         \
     --build-dir="$tmp_dir/ghc-lib/$version"               \
     "$no_threaded_rts_flag"                               \
)
