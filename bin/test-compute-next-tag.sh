#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# The variables derived from `dokuwiki_version` are in the fixture even though
# the script never reads them, and so is the `# renovate:` annotation, on the
# line it belongs on. Renovate edits the literal directly beneath it, so a
# refactor moving either the annotation or the tag computation onto a different
# variable would have them disagree about what a release is named after;
# keeping all of them in the fixture makes that show up here.
write_defaults() {
	local version="$1"

	cat > defaults/main.yml <<-EOF
		dokuwiki_identifier: dokuwiki

		# renovate: datasource=docker depName=dokuwiki/dokuwiki versioning=loose
		dokuwiki_version: ${version}

		dokuwiki_container_image: "{{ dokuwiki_container_image_registry_prefix }}dokuwiki/dokuwiki:{{ dokuwiki_container_image_tag }}"
		dokuwiki_container_image_tag: "{{ dokuwiki_version }}"

		dokuwiki_container_image_self_build_name: "dokuwiki/dokuwiki:{{ dokuwiki_container_image_self_build_version }}-self-build"
		dokuwiki_container_image_self_build_version: "{{ dokuwiki_version }}"

		dokuwiki_container_http_port: 8080
	EOF
}

# Starts a scenario with a repository at DokuWiki 2025-05-14b which has already
# seen two releases of it (v2025-05-14b-0 and v2025-05-14b-1).
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	write_defaults 2025-05-14b
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local release_number
	for release_number in 0 1; do
		git tag "v2025-05-14b-$release_number"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version='write_defaults 2026-07-14b'
revert_version='write_defaults 2025-05-14b'
prefix_version='write_defaults v2026-07-14b'
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v2026-07-14b-0 "$(merge "$bump_version")"
expect 'task edit'    v2026-07-14b-1 "$(merge "$edit_task")"
expect 'template'     v2026-07-14b-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v2025-05-14b-2 "$(merge "$edit_task")"
expect 'version bump' v2026-07-14b-0 "$(merge "$bump_version")"

scenario 'Commits that do not affect the role'
expect 'README'   ''              "$(merge "$edit_readme")"
expect 'a script' ''              "$(merge "$edit_script")"
expect 'a task'   v2025-05-14b-2  "$(merge "$edit_task")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v2025-05-14b-$release_number"
done
expect 'a task' v2025-05-14b-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v2025-05-14b-1 already published, so there
# is nothing new to release.
expect 'a revert' ''              "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v2025-05-14b-2  "$(merge "$revert_version && $edit_task")"

scenario 'A version value carrying a leading v does not double it in the tag'
expect 'version bump' v2026-07-14b-0 "$(merge "$prefix_version")"

# DokuWiki names its hotfix releases by appending a letter to the release date,
# so `2026-07-14` and `2026-07-14a` are two different releases whose tags share
# a prefix up to the letter. Reading the release counter off the wrong one would
# either skip release numbers or reuse an existing tag.
scenario 'A hotfix letter is not mistaken for the release counter'
merge "write_defaults 2026-07-14a" > /dev/null
for release_number in 1 2 3 4 5; do
	git tag "v2026-07-14a-$release_number"
done
expect 'the dated release'     v2026-07-14-0 "$(merge "write_defaults 2026-07-14")"
expect 'and a change to it'    v2026-07-14-1 "$(merge "$edit_task")"
expect 'back to the hotfix'    v2026-07-14a-6 "$(merge "write_defaults 2026-07-14a && $edit_template")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
