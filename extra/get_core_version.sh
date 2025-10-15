#!/bin/bash

# This script generates a SemVer-compatible version number based on Git tags.
#
# If the current commit is tagged, it returns that version. If not, it
# generates a version string based on the next patch number and the current
# commit hash.
#
# If the tag is a simple "<maj>.<min>.<patch>", git describe will output:
#
#     <maj>.<min>.<patch>-<number-of-commits-since-tag>-g<commit-hash-dirty>
#
# The regexp splits the patch number, awk converts the tokens to:
#
#     <maj>.<min>.<next-patch>-0.dev+<commit-hash-dirty>
#
# If the tag refers to a pre-release, like "<maj>.<min>.<patch>-<extra-stuff>",
# sed will output a total of 4 arguments and the format of the final awk output
# will be:
#
#     <maj>.<min>.<patch>-<extra-stuff>-0.dev+<commit-hash-dirty>
#
# These are among the lowest possible SemVer versions greater than the last
# tagged version.
#
# If there are no tags at all (for example when run in a fork etc), it defaults
# to "9.9.9-<date>+<commit-hash-dirty>".

VERSION=$(git describe --tags --exact-match 2>/dev/null)
if [ -z "$VERSION" ]; then
	VERSION=$(git describe --tags --dirty 2>/dev/null |
		sed 's/\.\([[:digit:]]\+\)\(-.*\)*-[[:digit:]]\+-g/ \1 \2 /' |
		awk '{ if (NF==3) { print $1 "." ($2+1) "-0.dev+" $3 } else { print $1 "." $2 $3 "-0.dev+" $4 }}')
	if [ -z "$VERSION" ]; then
		VERSION="9.9.9-$(date '+%Y%m%d-%H%M%S')+$(git describe --always --dirty)"
	fi
fi
echo $VERSION
