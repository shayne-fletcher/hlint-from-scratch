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

_________  --stack-yaml=ARG
    Stack configuration file.

  --resolver=ARG
    Stack resolver.

  --matrix-build
    Invoke matrix build behaviors.

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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

GHC_FLAVOR=""
no_builds=""
no_cabal=""
cabal_with_ghc="$(ghc --version | sed -e 's/The Glorious Glasgow Haskell Compilation System, version //g' -e 's/^/ghc-/g')"
stack_yaml=""
stack_yaml_flag=""
resolver=""
resolver_flag=""
repo_dir="$HOME/project"
with_haddock_flag="--with-hadock"
no_threaded_rts=false
no_threaded_rts_flag=""
no_checkout_flag=""
matrix_build=false

while [ $# -gt 0 ]; do
    if [ "$1" = "--help" ]; then
        echo "$usage" && exit 0
    elif [[ "$1" =~ --ghc-flavor=([^[:space:]]*) ]]; then
        GHC_FLAVOR="${BASH_REMATCH[1]}"
    elif [[ "$1" =~ --init=([^[:space:]]+) ]]; then
        repo_dir="${BASH_REMATCH[1]}"
        "$SCRIPT_DIR"/hlint-from-scratch-init.sh --repo-dir="$repo_dir"
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
    elif [ "$1" = "--matrix-build" ]; then
        matrix_build=true
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

echo "uname: $(uname)"
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

git checkout ghc-next

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
  echo "master: $HEAD"

  # If $HEAD agrees with the "last tested at" SHA in CI.hs stop here.
  current=$(grep "current = .*" CI.hs | grep -o "\".*\"" | cut -d "\"" -f 2)
  echo "CI.hs (last tested at): $current"
  # Skip this check in CI
  set +u
  if [ -z "${GHCLIB_AZURE}"]; then
      if [[ "$current" == "$HEAD" ]]; then
          echo "The last \"tested at\" SHA (\"$current\") hasn't changed"
          exit 99 # So as to stop e.g. stop 'hlint-from-scratch-matrix-build.sh' too.
      fi
  fi
  set -u

  # $HEAD is new. Summarize the new commits.
  (cd ghc && PAGER=cat git show $current..$HEAD --compact-summary)
   echo "-- "
fi

today=$(date -u +'%Y-%m-%d')
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master" ]]; then
  version="0.""$(date -u +'%Y%m%d')"
else
  flavor=$([[ "$GHC_FLAVOR" =~ (ghc\-)([0-9])\.([0-9][0-9]?)\.([0-9]) ]] && echo "${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}")
  version="$flavor"".""$(date -u +'%Y%m%d')"
fi

# Set these both to false for quick iteration. Set false/true for
# matrix builds.
if false; then
    rm -rf ~/.stack/programs/x86_64-osx/"$resolver"
    :
fi
if $matrix_build; then
  set +e
  rm -rf ~/.stack/snapshots/x86_64-osx/
  set -e
fi

# ghc-lib

cmd="$runhaskell $stack_yaml_flag $resolver_flag CI.hs -- $stack_yaml_flag $resolver_flag $no_checkout_flag $no_builds --ghc-flavor "
if [ -z "$GHC_FLAVOR" ]; then
    eval "$cmd" "$HEAD"
else
    eval "$cmd" "$GHC_FLAVOR"
fi

if [ -z "$GHC_FLAVOR" ]; then
    # If the above worked out, update CI.hs.
    if [ $(uname) == "Darwin" ]; then
        sed -i '' "s/current = \".*\" -- .*/current = \"$HEAD\" -- $today/g" "$repo_dir"/ghc-lib/CI.hs
    else
        sed -i'' "s/current = \".*\" -- .*/current = \"$HEAD\" -- $today/g" "$repo_dir"/ghc-lib/CI.hs
    fi
    # Report.
    grep "current = .*" "$repo_dir"/ghc-lib/CI.hs
fi

ghc_lib_parser_sha256=""
if [[ $(uname) == 'Darwin' ]]; then
  sha_ghc_lib_parser="$(shasum -a 256 "$repo_dir"/ghc-lib/ghc-lib-parser-"$version".tar.gz | awk '{ print $1 }')"
  ghc_lib_parser_sha256="sha256: \"${sha_ghc_lib_parser}\""
fi

# ghc-lib-parser-ex

cd "$repo_dir"/ghc-lib-parser-ex && git checkout .
if [ -z "$ghc_lib_parser_sha256" ]; then
  rm -f *.yaml.lock
fi

branch=$(git rev-parse --abbrev-ref HEAD)

# if the flavor indicates ghc's master branch get on
# ghc-lib-parser-ex's 'ghc-next' branch ...
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master" ]]; then
  if [[ "$branch" != "ghc-next" ]]; then
    echo "Not on ghc-next. Trying 'git checkout ghc-next'"
    git checkout ghc-next
  fi
# # if the flavor indicates ghc's 9.10.1 branch get on
# # ghc-lib-parser-ex's 'ghc-next' branch (yes, ghc-next) ...
# elif [[ "$GHC_FLAVOR" == "ghc-9.10.1" ]]; then
#   if [[ "$branch" != "ghc-next" ]]; then
#     echo "Not on ghc-next. Trying 'git checkout ghc-next'"
#     git checkout ghc-next
#   fi
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

# Record the ghc-version (e.g. 9.8.1).
build_comp_version="$(stack $stack_yaml_flag $resolver_flag --silent exec -- ghc --version | sed 's/The Glorious Glasgow Haskell Compilation System, version //g')"

# This an elaborate step to create a config file'stack-head.yaml'.
#
# If a stack-yaml argument was provided, seed its contents from it
# otherwise, assume a curated $resolver and create it from scratch.

# Enable 'allow-newer' if using ghc-9.10.1.
allow_newer=""
if [[ "$build_comp_version" == 9.10.* ]]; then
  allow_newer="allow-newer: True"
fi

# windows hack: repo_dir_stripped is the path with ^/[a-z]/ removed
# e.g. /c/users/... -> /users/...
repo_dir_stripped=$(echo "${repo_dir}" | sed -e "s;^/./;/;g")

if [[ -n "$stack_yaml" ]]; then
  echo "Seeding stack-head.yaml from $stack_yaml"
  # shellcheck disable=SC2002
  cat "$stack_yaml" | \
  # Delete any pre-existing ghc-lib-parser extra dependency.
  sed -e "s;^.*ghc-lib-parser.*$;;g" | \
  sed -e "s;^extra-deps:$;\
# enable ghc-9.8.1 as a build compiler (base-4.19.0)\n\
# --\n\
$allow_newer\n\
# --\n\
extra-deps:\n\
  - archive: ${repo_dir_stripped}/ghc-lib/ghc-lib-parser-${version}.tar.gz\n\
    ${ghc_lib_parser_sha256};\
g" | \
  sed -e "s;- extra-1.7.14;-../extra;g" | \
  sed -e "s;^resolver:.*$;resolver: ${resolver};g" > stack-head.yaml
else
  cat > stack-head.yaml <<EOF
resolver: $resolver
extra-deps:
  - archive: ${repo_dir_stripped}/ghc-lib/ghc-lib-parser-${version}.tar.gz\n\
    ${ghc_lib_parser_sha256};\
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
cat "$stack_yaml"
eval "$runhaskell $stack_yaml_flag CI.hs -- $no_builds $stack_yaml_flag --version-tag $version"

ghc_lib_parser_ex_sha256=""
if [ $(uname) == 'Darwin' ]; then
  sha_ghc_lib_parser_ex=$(shasum -a 256 "$repo_dir"/ghc-lib-parser-ex/ghc-lib-parser-ex-"$version".tar.gz | awk '{ print $1 }')
  ghc_lib_parser_ex_sha256="sha256: \"${sha_ghc_lib_parser_ex}\""
fi

# Hlint

cd "$repo_dir"/hlint && git checkout .
if [ -z "$ghc_lib_parser_sha256" ] || [ -z "$ghc_lib_parser_ex_sha256" ]; then
  rm -f *.yaml.lock
fi

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
elif [[ "$GHC_FLAVOR" == "ghc-9.10.1" ]]; then
  if [[ "$branch" != "ghc-9.10.1" ]]; then
    echo "Not on ghc-9.10.1. Trying 'git checkout ghc-9.10.1'"
    git checkout ghc-9.10.1
  fi
else
  if [[ "$branch" != "master" ]]; then
      echo "Not on master. Trying 'git checkout master'"
      git checkout master
  fi
fi

# We're stuck with only curated resolvers for hlint at this time.
if [[ -z "$GHC_FLAVOR" \
   || "$GHC_FLAVOR" == "ghc-master" \
   || "$GHC_FLAVOR" == "ghc-9.10.1"
 ]]; then
  # ghc-flavor >= ghc-master
  resolver=lts-22.11 # ghc-9.6.4
else
  resolver=lts-21.6 # ghc-9.4.5
fi

# Currently in sync with 'hlint/stack.yaml'.

cat > stack-head.yaml <<EOF
resolver: $resolver
packages:
- .
extra-deps:
  - archive: ${repo_dir_stripped}/ghc-lib/ghc-lib-parser-${version}.tar.gz
    ${ghc_lib_parser_sha256}
  - archive: ${repo_dir_stripped}/ghc-lib-parser-ex/ghc-lib-parser-ex-$version.tar.gz
    ${ghc_lib_parser_ex_sha256}
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
#if true; then
if [ true ]; then
# if ! [ "$no_builds" == --no-builds ]; then
  # Again, wrong to pass $resolver_flag here.

  C_INCLUDE_PATH=""
  if [ $(uname) == 'Darwin' ]; then
      C_INCLUDE_PATH="$(xcrun --show-sdk-path)"/usr/include/ffi
  fi

  # Build hlint.
  eval "C_INCLUDE_PATH=$C_INCLUDE_PATH" "stack" "$stack_yaml_flag" "build"

  # Run its tests.
  eval "C_INCLUDE_PATH=$C_INCLUDE_PATH" "stack" "$stack_yaml_flag" "run" "--" "--test"

  # Test there are no changes to 'hints.md'.
  eval "C_INCLUDE_PATH=$C_INCLUDE_PATH" "stack" "$stack_yaml_flag" "run" "--" "hlint" "--generate-summary"

  git diff --exit-code hints.md

  # Run it on its own source.
  eval "C_INCLUDE_PATH=$C_INCLUDE_PATH" "stack" "$stack_yaml_flag" "run" "--" "src"
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
echo "phase test-ghc-9.0.sh in $(pwd)"

if [ $(uname) == "Darwin" ]; then
  sed -i '' "s/^version:.*\$/version:            $version/g" hlint.cabal
  sed -i '' "s/^.*ghc-lib-parser ==.*\$/          ghc-lib-parser == $version/g" hlint.cabal
  sed -i '' "s/^.*ghc-lib-parser-ex >=.*\$/          ghc-lib-parser-ex == $version/g" hlint.cabal
  # sarif tests encode the current hlint version number
  sed -i '' "s/3.5/$version/g" tests/sarif.test # hack. see issue https://github.com/ndmitchell/hlint/issues/1492
else
  sed -i'' "s/^version:.*\$/version:            $version/g" hlint.cabal
  sed -i'' "s/^.*ghc-lib-parser ==.*\$/          ghc-lib-parser == $version/g" hlint.cabal
  sed -i'' "s/^.*ghc-lib-parser-ex >=.*\$/          ghc-lib-parser-ex == $version/g" hlint.cabal
  # sarif tests encode the current hlint version number
  sed -i'' "s/3.5/$version/g" tests/sarif.test # hack. see issue https://github.com/ndmitchell/hlint/issues/1492
fi
eval "stack" "$stack_yaml_flag" "sdist" "." "--tar-dir" "."

# - Generate a cabal.project of
#   - ghc-lib, ghc-lib-parser-ex, examples, hlint
#     - (somwhere like ~/tmp/ghc-lib/ghc-lib-9.4.3.20221104/ghc-9.4.1/cabal.project
# - and `cabal new-build all`.
# - Maybe produce haddocks too
#   - Depending on the contents of `$with_haddock_flag`. Also,
# - Run ghc-lib-test-mini-hlint, ghc-lib-test-mini-compile and the
#   hlint test suite.
tmp_dir=$HOME/tmp
mkdir -p "$tmp_dir"
(cd "$tmp_dir" && "$SCRIPT_DIR"/hlint-from-scratch-cabal-build-test.sh  \
     "$cabal_with_ghc_flag"                                \
     --version-tag="$version"                              \
     --ghc-lib-dir="$repo_dir/ghc-lib"                     \
     --ghc-lib-parser-ex-dir="$repo_dir/ghc-lib-parser-ex" \
     --hlint-dir="$repo_dir/hlint"                         \
     --build-dir="$tmp_dir/ghc-lib/$version"               \
     "$no_threaded_rts_flag"                               \
)
