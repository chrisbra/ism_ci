#!/bin/bash

#set -x
set -eo pipefail

project="ism_ci"
config="ismci"
dir="/home/ibuser/iwaySDK/8.0.4/build2/projects/"
iwayhome="/home/ibuser/iway8/"
LOGFILE="/tmp/CI_LOGFILE_$$.log"

# Read in some common definitions
. "$(dirname $0)"/library.sh

startup_ism () {
  printf "\n${blue}Starting iSM Server Up...\t\t\t"
	cd ~/iway8
	sed -i.bak -e '/^ *su/{s/^[^"]*"//;s/"$//}' bin/startservice.sh
	bin/startservice.sh base >"$LOGFILE" 2>&1
	sleep 20
	print_status 0
}

validate_ism_access () {
	printf "${blue}Trying to access iSM Webconsole...\t\t"
	curl -L -s --user "iway:iway" http://localhost:9999/ism >/dev/null
	print_status $?
}


copy_project_to_iwaysdk () {
  printf "${blue}Copying %s project to iway build dir...\t" "$project"
	ln -s ~/project/ "${dir}${project}"
	print_status $?
}

checkout_iwaysdk_configuration () {
	cd "${dir}/../configurations"
	printf "${blue}Checking out iwaysdk Configuration...\t\t"
	git clone --quiet --depth=1 https://github.com/chrisbra/ci_configuration ismci
	print_status $?
}

patching_iwaysdk () {
	cd "${dir}/.."
	printf "${blue}Patching iwaysdk build.sh ...\t\t\t"
	sed -i.bak -e 's/exit 0/exit \$?/' -e 's/ant \(start\|stop\) /ant \1app /' build.sh
	print_status $?
	printf "${blue}make iwaySDK executable ...\t\t\t"
	chmod +x build.sh
	print_status $?
}

build_deploy_start () {
	cd "${dir}/.." > /dev/null
	printf "${blue}Building %s project for iSM ...\t\t" "$project"
	sh build.sh BUILDAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
	printf "${blue}Deploying %s project for iSM ...\t\t" "$project"
	sh build.sh DEPLOYAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
	printf "${blue}Starting %s app for iSM ...\t\t" "$project"
	sh build.sh STARTAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
}

setup_project_files () {
	printf "${blue}Creating directory structure for ism project...\t"
	mkdir -p "${iwayhome}/processing" && 
	mkdir -p "${iwayhome}/processing/input" &&
	mkdir -p "${iwayhome}/processing/archive" &&
	mkdir -p "${iwayhome}/processing/output" &&
	mkdir -p "${iwayhome}/processing/output/status"
	print_status $?
}

startup_ism
validate_ism_access
copy_project_to_iwaysdk
checkout_iwaysdk_configuration
patching_iwaysdk
setup_project_files
build_deploy_start

printf "${green}DONE${reset}\n"
