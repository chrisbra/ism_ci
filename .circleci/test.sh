#!/bin/bash
#set -eo pipefail

# Setup some color variables
export red=$(tput -T xterm setaf 1)
export green=$(tput -T xterm setaf 2)
export blue=$(tput -T xterm setaf 4)
export yellow=$(tput -T xterm setaf 3)
export reset=$(tput -T xterm sgr0)

INPUT=/home/ibuser/iway8/processing/input/
OUTPUT=/home/ibuser/iway8/processing/output/

FILES=/home/ibuser/project/Resources/Tests/input
EXPECTED=/home/ibuser/project/Resources/Tests/expected


# Run the test cases

setup_and_run () {
		printf "${blue}$1${reset}\n"
}

cleanup_ism_working_dir () {
	find $INPUT -type f -delete
	find $OUTPUT -type f -delete
}

diff_result () {
	# preprocess and remove timestamp
	printf "Diffing resulting files $(basename $1) $(basename $2)\t\t"
	for file; do
		sed -i -e 's#<timestamp>.*</timestamp>#<timestamp>TIMESTAMP</timestamp>#' $file
	done
	DIFFERENCE=$(git diff --no-index --no-ext-diff --exit-code $1 $2)
	if [ $? -gt 0 ]; then
		printf "${red}[FAILED]${reset}\n"
		echo "$DIFFERENCE"
	else
		printf "${green}[OK]${reset}\n"
	fi
}

for file in $FILES/*; do
	setup_and_run "Test case 1"
	cp "$file" "$INPUT"
	# Give iSM a chance to process it
	i="0"
	result="$(basename ${file} .xlsx)".xml
	exp_output=$EXPECTED/output/$result
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
	exp_status=$EXPECTED/output/status/*
	# Get 2 resulting files: Output and Status
	diff_result $result $exp_output
	diff_result $OUTPUT/status/* $exp_status
	# TODO enable later again
	#cleanup_ism_working_dir
done
