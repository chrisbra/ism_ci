#!/bin/bash

#set -x

project="ism_ci"
config="ismci"
dir="/home/ibuser/iwaySDK/8.0.4/build2/projects/"

LOGFILE="/tmp/CI_LOGFILE_$$.log"

# Setup some color variables
export red=$(tput -T xterm setaf 1)
export green=$(tput -T xterm setaf 2)
export blue=$(tput -T xterm setaf 4)
export yellow=$(tput -T xterm setaf 3)
export reset=$(tput -T xterm sgr0)

print_status () {
	if [ $1 -eq 0 ]; then
		printf "${green}[OK]${reset}\n"
	else
		printf "${red}[FAILED]${reset}\n"
		if [ -f "$LOGFILE" ]; then
			cat "$LOGFILE"
		fi
		exit 1
	fi
}

(
  printf "\n${blue}Starting iSM Server Up...\t"
	pushd -n ~/iway8
	sed -i.bak -e '/^ *su/{s/^[^"]*"//;s/"$//}' bin/startservice.sh
	bin/startservice.sh base >"$LOGFILE" 2>&1
	sleep 20
	print_status 0
)

(
	printf "${blue}Trying to access iSM Webconsole.....\t"
	curl -L -s --user "${IWAY_USER}:${IWAY_PASS}" http://localhost:9999/ism
	printf "\n-------\nResult: %s\n--------\n" $?
	
	if [ $? -eq 7 ]; then
		printf "${red}[FAILED]${reset}\n"
	else
		printf "${green}[OK]${reset}\n"
	fi
)


(
  printf "${blue}Copying %s project to iwaysdk build directory\t" "$project"
	ln -s -t "$dir" ~/project/ "$project"
	print_status $?
)

(
	pushd -n "${dir}/../configurations"
	printf "${blue}Checking out iwaysdk Configuration.....\t"
	git clone --quiet --depth=1 https://github.com/chrisbra/ci_configuration ismci
	print_status $?
)

(
	pushd -n "${dir}/.."
	printf "${blue}Patching iwaysdk build.sh .....\t"
	sed -i.bak -e 's/exit 0/exit \$?/' -e 's/ant \(start\|stop\) /ant \1app ' build.sh
	print_status $?
	printf "${blue}make iwaySDK executable .....\t"
	chmod +x build.sh
	print_status $?
)


(
	pushd -n "${dir}/.." > /dev/null
	printf "${blue}Building %s project for iSM .....\t" "$project"
	sh build.sh BUILDAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
	printf "${blue}Deploying %s project for iSM .....\t" "$project"
	sh build.sh DEPLOYAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
	printf "${blue}Starting %s app for iSM .....\t" "$project"
	sh build.sh STARTAPP "$config" >"$LOGFILE" 2>&1
	print_status $?
)

printf "${green}DONE${reset}\n"
