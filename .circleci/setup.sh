#!/bin/bash

#set -x

project="ism_ci"
dir="/home/ibuser/iwaySDK/8.0.4/build2/projects/"

# Setup some color variables
export red=$(tput -T xterm setaf 1)
export green=$(tput -T xterm setaf 2)
export blue=$(tput -T xterm setaf 4)
export yellow=$(tput -T xterm setaf 3)
export reset=$(tput -T xterm sgr0)

function status(rc) {
	if [ $1 -eq 0 ];
		printf "${green}[OK]${reset}\n"
	else
		printf "${red}[FAILED]${reset}\n"
		# TODO: Fail with error
	fi
}

(
  printf "\n${blue}Starting iSM Server Up\n"
	pushd ~/iway8
	sed -i.bak -e '/^ *su/{s/^[^"]*"//;s/"$//}' bin/startservice.sh
	bin/startservice.sh base >/dev/null
	sleep 20
)

(
	printf "${blue}Trying to access iSM Webconsole.....\t"
	curl -L -s --user "${IWAY_USER}:${IWAY_PASS}" http://localhost:9999/ism >/dev/null
	if [ $? -eq 7 ]; then
		printf "${red}[FAILED]${reset}\n"
	else
		printf "${green}[OK]${reset}\n"
	fi
)


(
  printf "${blue}Copying %s project to iwaysdk build directory\n" "$project"
	ln -s ~/project "${dir}${project}"
	status($?)
)

(
	printf "${blue}Checking out iwaysdk Configuration.....\t"
	pushd "${dir}/../configurations"
	git clone --quiet --depth=1 https://github.com/chrisbra/ci_configuration ismci
	status($?)
)

(
	printf "${blue}Patching iwaysdk build.sh .....\t"
	pushd "${dir}/.."
	sed -i.bak -e 's/exit 0/exit \$?/' build.sh
	status($?)
	printf "${blue}make iwaysdk executable .....\t"
	chmod +x build.sh
	status($?)
)


(
	printf "${blue}Building %s project for iSM .....\t" "$project"
	pushd "${dir}/.."
	sh build.sh BUILDAPP ismci
	status($?)
	printf "${blue}Deploying %s project for iSM .....\t" "$project"
	sh build.sh DEPLOYAPP ismci
	status($?)
)

printf "${green}DONE${reset}"
