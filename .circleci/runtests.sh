#!/bin/bash
set -o pipefail

# Read in some common definitions
. "$(dirname $0)"/library.sh

IWAY8=/home/ibuser/iway8

INPUT=$IWAY8/processing/input/
OUTPUT=$IWAY8/processing/output/
ARCHIVE=$IWAY8/processing/archive/

FILES=/home/ibuser/project/Resources/Tests/input/
EXPECTED=/home/ibuser/project/Resources/Tests/expected/
exitcode=0

TESTRESULT=~/test-results/xml/result.xml
TESTS=0

# Run the test cases

setup_and_run () {
		printf "${blue}$1${reset}\n"
}

cleanup_ism_working_dir () {
	find $INPUT -type f -delete
	find $OUTPUT -type f -delete
	find $ARCHIVE -type f -delete
}

write_test_result_start () {
cat << EOF > $TESTRESULT
<?xml version="1.0" encoding="UTF-8"?>
<testsuite tests="###">
EOF
}

write_test_result_end () {
cat << EOF >> $TESTRESULT
</testsuite>
EOF
sed -i -e "s/tests=\"###\"/tests=\"$TESTS\"/" $TESTRESULT
}

write_test_result () {
	if [ $2 -eq 0 ]; then
		cat <<EOF >> $TESTRESULT
	<testcase name="testcase $testcase $1" classname="iSM.transformation" time="$DUATION"/>
EOF
  else
		cat <<EOF >> $TESTRESULT
	<testcase name="testcase $testcase $1" classname="iSM.transformation" time="$DUATION"/>
		<failure message="git diff returned an error between expected and actual "$1" file">
$DIFFERENCE
		</failure>
	</testcase>
EOF
	fi
}

preprocess_files () {
	# preprocess and remove timestamp
	printf "    ${blue}preprocessing input files... \t\t"
	for file; do
		sed -i -e 's#<timestamp>.*</timestamp>#<timestamp>TIMESTAMP</timestamp>#' $file
	done
	print_status $?
}

diff_result () {
	preprocess_files "$2" "$3"
	printf "    ${blue}Diffing ${yellow}$1${blue} files $(basename $2) $(basename $3)\t\t"
	DIFFERENCE="$(git diff --no-index --no-ext-diff --exit-code $2 $3)"
	rc=$?
	# do not yet abort
	( print_status $rc ) || true
	if [ $rc -gt 0 ]; then
		printf "Difference\n---------\n%s\n---------\n" "$DIFFERENCE"
		exitcode=$[$exitcode + $rc]
	fi
	write_test_result $1 $rc
}

run_tests () {
	for testdir in $FILES/*; do
		testcase="$(basename $testdir /)"
		TESTS=$[TESTS + 3]
		STARTTIME=`date +%s`
		setup_and_run "${testcase}) Test case"
		# There should only be one single file in the input directory,
		# but we do not know how it is called, so use a loop :)
		for inputfile in $testdir/*; do
			cp "$inputfile" "$INPUT"
			i="0"
			result="$(basename ${inputfile} .xlsx)".xml
			exp_output=$EXPECTED/$testcase/$result
			result=$OUTPUT/$result
			# Give iSM a chance to process it
			# so check every 5 seconds if the file has been processed
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
			ENDTIME=$(date +%s)
			DURATION=$[$ENDTIME - $STARTTIME]
			exp_status=$EXPECTED/$testcase/status/*
			# We need to test 3 different cases here:
			# 1) The transformed Output File
			diff_result "output" $result $exp_output
			# 2) The Status File
			diff_result "status" $OUTPUT/status/* $exp_status
			# 3) The archived File
			diff_result "archive" $ARCHIVE/* $inputfile
		done
		cleanup_ism_working_dir
	done
}

# Fake writing Junit XML file
# see https://stackoverflow.com/questions/4922867/what-is-the-junit-xml-format-specification-that-hudson-supports
write_test_result_start
# run the actual tests
run_tests

Finish the XML file
write_test_result_end

exit $exitcode
