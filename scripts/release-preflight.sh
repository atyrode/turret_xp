#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

channel="${1:-release}"
remote="${RELEASE_REMOTE:-origin}"
branch="${RELEASE_SOURCE_BRANCH:-main}"
remote_ref="refs/remotes/${remote}/${branch}"

fail() {
  echo "Release preflight failed for ${channel}: $*" >&2
  exit 1
}

current_branch="$(git symbolic-ref --quiet --short HEAD || true)"
if [ -z "$current_branch" ]; then
  fail "HEAD is detached; expected branch ${branch}."
fi

if [ "$current_branch" != "$branch" ]; then
  fail "current branch is ${current_branch}; expected ${branch}."
fi

if [ -n "$(git status --porcelain)" ]; then
  fail "working tree is not clean. Commit, stash, or discard local changes before publishing."
fi

git fetch "$remote" "$branch" --prune

if ! git show-ref --verify --quiet "$remote_ref"; then
  fail "remote branch ${remote}/${branch} was not found."
fi

local_head="$(git rev-parse HEAD)"
remote_head="$(git rev-parse "$remote_ref")"
merge_base="$(git merge-base HEAD "$remote_ref")"

if [ "$local_head" = "$remote_head" ]; then
  echo "Release preflight passed for ${channel}: ${branch} matches ${remote}/${branch} at ${local_head}."
  exit 0
fi

if [ "$merge_base" = "$local_head" ]; then
  fail "local ${branch} is behind ${remote}/${branch}. Pull or fast-forward before publishing."
elif [ "$merge_base" = "$remote_head" ]; then
  fail "local ${branch} has commits not pushed to ${remote}/${branch}. Push them before publishing."
else
  fail "local ${branch} has diverged from ${remote}/${branch}. Resolve the divergence before publishing."
fi
