#!/usr/bin/env bash
# fetch-sampalx.sh — idempotent fetch of the SampaLX MiniLibX replacement
# (WebGL/emscripten build) into lib/sampalx/.
#
# Usage: bash scripts/fetch-sampalx.sh
#
# - Clones herom-s/SampaLX @ feat/webgl-support via `gh repo clone` when
#   lib/sampalx/ does not exist.
# - Falls back to a plain `git clone` when `gh` is unavailable.
# - When lib/sampalx/ already exists, it is left untouched unless it is on a
#   different ref than expected, in which case it is fetched + checked out.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${REPO_ROOT}/lib/sampalx"
REPO_SLUG="herom-s/SampaLX"
BRANCH="feat/webgl-support"

if [ -e "${DEST}" ]; then
	if git -C "${DEST}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		current="$(git -C "${DEST}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
		if [ "${current}" = "${BRANCH}" ]; then
			echo "[fetch-sampalx] lib/sampalx already on branch '${BRANCH}' — nothing to do."
			exit 0
		fi
		echo "[fetch-sampalx] lib/sampalx exists but is on '${current}' — fetching '${BRANCH}'..."
		git -C "${DEST}" fetch --depth 1 origin "${BRANCH}" >/dev/null 2>&1 \
			|| git -C "${DEST}" fetch origin "${BRANCH}"
		git -C "${DEST}" checkout -B "${BRANCH}" "origin/${BRANCH}" >/dev/null
	else
		echo "[fetch-sampalx] ${DEST} exists but is not a git worktree — leaving it alone." >&2
		exit 0
	fi
	exit 0
fi

mkdir -p "$(dirname "${DEST}")"
if command -v gh >/dev/null 2>&1; then
	echo "[fetch-sampalx] cloning ${REPO_SLUG} (branch ${BRANCH}) via gh..."
	gh repo clone "${REPO_SLUG}" "${DEST}" -- --branch "${BRANCH}" --depth 1
else
	echo "[fetch-sampalx] gh not found — falling back to git clone..."
	git clone --branch "${BRANCH}" --depth 1 \
		"https://github.com/${REPO_SLUG}.git" "${DEST}"
fi

echo "[fetch-sampalx] done: $(git -C "${DEST}" rev-parse --short HEAD) (${BRANCH})"
