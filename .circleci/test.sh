#!/bin/bash
#set -eo pipefail

# Read in some common definitions
. "$(dirname $0)"/library.sh

IWAY8=/home/ibuser/iway8

INPUT=$IWAY8/processing/input/
OUTPUT=$IWAY8/processing/output/
ARCHIVE=$IWAY8/processing/archive/

FILES=/home/ibuser/project/Resources/Tests/input/
EXPECTED=/home/ibuser/project/Resources/Tests/expected/


# Run the test cases

setup_and_run () {
		printf "${blue}$1${reset}\n"
}

cleanup_ism_working_dir () {
	find $INPUT -type f -delete
	find $OUTPUT -type f -delete
}

preprocess_files () {
	# preprocess and remove timestamp
	printf "${blue}preprocessing input files... \t\t"
	for file; do
		sed -i -e 's#<timestamp>.*</timestamp>#<timestamp>TIMESTAMP</timestamp>#' $file
	done
	print_status $?
}

diff_result () {
	printf "${blue}Diffing $1 files $(basename $2) $(basename $3)\t\t"
	DIFFERENCE=$(git diff --no-index --no-ext-diff --exit-code $1 $2)
	rc=$?
	print_status $rc
	if [ $rc -gt 0 ]; then
		echo "$DIFFERENCE"
		exit 1
	fi
}

for testdir in $FILES/*; do
	setup_and_run "Test case $testdir"
	# There should only be one single file in the input directory,
	# but we do not know how it is called, so use a loop :)
	testcase="$(basename $testdir)"
	for file in $testdir/*; do
		cp "$file" "$INPUT"
		# Give iSM a chance to process it
		i="0"
		result="$(basename ${file} .xlsx)".xml
		exp_output=$EXPECTED/$testcase/output/$result
		result=$OUTPUT/$result
		while [ ! -f $result ]; do
			sleep 5s
			i=$[$i+1]
			if [ $i -ge 10 ]; then
				break
			fi
		done
		if [ ! -f $result ]; then
				printf "${red}Resulting File does not appear: ${result}"
				exit 1
		fi
		exp_status=$EXPECTED/$testcase/output/status/*
		# We need to test 3 different cases here:
		# 1) The transformed Output File
		diff_result "output" $result $exp_output
		# 2) The Status File
		diff_result "status" $OUTPUT/status/* $exp_status
		# 3) The archived File
		diff_result "archive" $ARCHIVE/* $file
	done
	cleanup_ism_working_dir
done
