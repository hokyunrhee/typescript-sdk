#!/usr/bin/env bash
# Maps the files a pull request changed to the Vitest roots nyorori must run in.
#
# Usage: bash .github/nyorori-roots.sh <base> [<head>]
#   Run from the repository root. <base> and <head> are git refs; the diff is
#   <base>...<head> (from their merge-base), as nyorori computes it.
#
# A root is the deepest directory above a changed file that holds a
# vitest.config.* file. Only JS/TS files and the component formats nyorori
# refuses (.vue, .svelte, .astro, .mdx, .marko, .gjs, .gts) count.
#
# Output, for $GITHUB_OUTPUT:
#   matrix=[{"root":..,"build":..,"node_options":..,"exclude":..}, ...]
# A Markdown report of the mapping goes to stderr and, in Actions, to the job summary.
set -euo pipefail
base=$1
head=${2:-HEAD}

# Per-root settings for this repository. Sets skip, build, node_options, exclude.
root_config() {
  skip='' build='' node_options='' exclude=''
  case "$1" in
    common/vitest-config)
      skip='the shared Vitest config package; it has no tests' ;;
    test/helpers)
      skip='test helpers with no tests of their own; other roots import them' ;;
    test/conformance)
      skip='conformance harness driven by an external referee, not by Vitest tests' ;;
    test/integration|test/e2e)
      # Fixture servers run as child processes, where nyorori cannot see them run; they would be NoCoverage.
      exclude=$'**/__fixtures__/**\n**/fixtures/**' ;;
  esac
}

summary() {
  printf '%s\n' "$@" >&2
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then printf '%s\n' "$@" >> "$GITHUB_STEP_SUMMARY"; fi
}

configs=$(git ls-files -- '*vitest.config.*' | grep -E '(^|/)vitest\.config\.[cm]?[jt]s$' || true)
declare -A is_root=()
while IFS= read -r d; do
  [ -n "$d" ] && is_root[$d]=1
done < <(printf '%s\n' "$configs" | grep . | sed -E 's#(^|/)vitest\.config\.[cm]?[jt]s$##; s#^$#.#')

declare -A files_of=()
noroot=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  d=$(dirname "$f")
  root=''
  while :; do
    if [ -n "${is_root[$d]:-}" ]; then root=$d; break; fi
    [ "$d" = . ] && break
    d=$(dirname "$d")
  done
  if [ -z "$root" ]; then noroot+=("$f"); continue; fi
  files_of[$root]+="$f "
done < <(git diff --name-only --no-renames "$base...$head" -- \
  '*.js' '*.jsx' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.mts' '*.cts' \
  '*.vue' '*.svelte' '*.astro' '*.mdx' '*.marko' '*.gjs' '*.gts')

matrix='[]'
summary '## nyorori roots' '' '| Root | Changed files | Run |' '|---|---|---|'
for root in $( (( ${#files_of[@]} )) && printf '%s\n' "${!files_of[@]}" | sort); do
  root_config "$root"
  n=$(wc -w <<< "${files_of[$root]}")
  if [ -n "$skip" ]; then
    summary "| \`$root\` | $n | skipped: $skip |"
    continue
  fi
  summary "| \`$root\` | $n | yes |"
  matrix=$(jq -c --arg root "$root" --arg build "$build" --arg node_options "$node_options" --arg exclude "$exclude" \
    '. + [{root: $root, build: $build, node_options: $node_options, exclude: $exclude}]' <<< "$matrix")
done
if [ ${#noroot[@]} -gt 0 ]; then
  summary '' "${#noroot[@]} changed file(s) under no Vitest root: ${noroot[*]}"
fi
echo "matrix=$matrix"
