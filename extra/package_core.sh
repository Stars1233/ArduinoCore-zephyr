#!/bin/bash

set -e

if [ -z "$1" ]; then
	echo "Usage: $0 ARTIFACT VERSION [OUTPUT_FILE]"
	exit 1
fi

if [ ! -f platform.txt ]; then
	echo "Launch this script from the root core folder."
	exit 2
fi

ARTIFACT=$1
VERSION=$2
OUTPUT_FILE=${3:-distrib/${ARTIFACT}-${VERSION}.tar.bz2}

# we use variants for include because we filter on file paths
# and boards for exclude because we want to remove matching lines in boards.txt
BOARD_DETAILS=$(extra/get_board_details.sh)
if [ $ARTIFACT == "zephyr" ] ; then
	INCLUDED_VARIANTS=$(echo ${BOARD_DETAILS} | jq -cr ".[].variant")
	EXCLUDED_BOARDS=""
elif [ ! -f extra/artifacts/${ARTIFACT}.json ]; then
	echo "Unknown artifact '$ARTIFACT'."
	exit 3
else
	ARTIFACT_NAME="$(grep '"name"' extra/artifacts/${ARTIFACT}.json | head -n 1 | cut -d '"' -f 4) (${VERSION})"
	INCLUDED_VARIANTS=$(echo ${BOARD_DETAILS} | jq -cr "map(select(.artifact == \"$ARTIFACT\")) | .[].variant")
	EXCLUDED_BOARDS=$(echo ${BOARD_DETAILS} | jq -cr "map(select(.artifact != \"$ARTIFACT\")) | .[].board")
fi

[ -n $GITHUB_WORKSPACE ] && echo "::group::Packaging ${ARTIFACT_NAME:-all variants} ($(basename $OUTPUT_FILE))"

# create a temporary boards.txt file with the correct list of boards
TEMP_BOARDS=$(mktemp -p . | sed 's/\.\///')
cat boards.txt >> $TEMP_BOARDS
for board in $EXCLUDED_BOARDS ; do
	# remove (even commented) lines for excluded boards
	sed -i "/^\(\s*#\s*\)\?${board}\./d" $TEMP_BOARDS
done
# remove multiple empty lines
sed -i '/^$/N;/^\n$/D' $TEMP_BOARDS

# create a temporary platform.txt file with the correct version
TEMP_PLATFORM=$(mktemp -p . | sed 's/\.\///')
cat platform.txt > ${TEMP_PLATFORM}
[ -z "$ARTIFACT_NAME" ] || sed -ie "s/^name=.*/name=${ARTIFACT_NAME}/" ${TEMP_PLATFORM}
sed -ie "s/^version=.*/version=$(extra/get_core_version.sh)/" ${TEMP_PLATFORM}

declutter_file() {
	[ -f "$1" ] || return 0
	cat "$1" | sed -e 's/\s*#.*//' | grep -v '^\s*$'
}

# create the list of files and directories to include
TEMP_INC=$(mktemp -p . | sed 's/\.\///')
echo ${TEMP_BOARDS} >> ${TEMP_INC}
echo ${TEMP_PLATFORM} >> ${TEMP_INC}
declutter_file extra/artifacts/_common.inc >> ${TEMP_INC}
declutter_file extra/artifacts/$ARTIFACT.inc >> ${TEMP_INC}
for variant in $INCLUDED_VARIANTS ; do
	echo "::info::\`${variant}\`"
	echo "variants/${variant}/" >> ${TEMP_INC}
	ls firmwares/zephyr-${variant}.* >> ${TEMP_INC}
done

# create the list of files and directories to exclude
TEMP_EXC=$(mktemp -p . | sed 's/\.\///')
declutter_file extra/artifacts/_common.exc >> ${TEMP_EXC}
declutter_file extra/artifacts/$ARTIFACT.exc >> ${TEMP_EXC}

mkdir -p $(dirname ${OUTPUT_FILE})
tar -cjhf ${OUTPUT_FILE} -X ${TEMP_EXC} -T ${TEMP_INC} \
	--transform "s,${TEMP_BOARDS},boards.txt," \
	--transform "s,${TEMP_PLATFORM},platform.txt," \
	--transform "s,^,ArduinoCore-zephyr/,"
rm -f ${TEMP_INC} ${TEMP_EXC} ${TEMP_BOARDS} ${TEMP_PLATFORM}

[ -n $GITHUB_WORKSPACE ] && echo "::endgroup::"
