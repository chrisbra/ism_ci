#!/bin/bash

set -x

project="ism_ci"
dir="/home/ibuser/iwaySDK/8.0.4/build2/projects/"

(
  printf "\nStarting iSM Server Up\n"
	pushd ~/iway8
	sed -i.bak -e '/^ *su/{s/^[^"]*"//;s/"$//}' bin/startservice.sh
	bin/startservice.sh base
	#popd
	sleep 20
)

(
	printf "Trying to access iSM Webconsole.....\t"
	curl -L -s --user "${IWAY_USER}:${IWAY_PASS}" http://localhost:9999/ism >/dev/null
	if [ $? -eq 7 ]; then
		printf "[FAILED]\n"
	else
		printf "[OK]\n"
	fi
)


  printf "Copying %s project to iwaysdk build directory\n" "$project"
	ln -s ~/project "${dir}${project}"

(
	printf "Checking out iwaysdk Configuration.....\t"
	pushd "${dir}/../configurations"
	git clone --quiet --depth=1 https://github.com/chrisbra/ci_configuration ismci
	if [ $? -eq 0 ]; then
		printf "[OK]\n"
	else
		printf "[FAILED]\n"
	fi
	#popd
)

(
	printf "Patching iwaysdk build.sh .....\t"
	pushd "${dir}/.."
	sed -i.bak -e 's/exit 0/exit \$?/' build.sh
	if [ $? -eq 0 ]; then
		printf "[OK]\n"
	else
		printf "[FAILED]\n"
	fi
	printf "make iwaysdk executable .....\t"
	chmod +x build.sh
	if [ $? -eq 0 ]; then
		printf "[OK]\n"
	else
		printf "[FAILED]\n"
	fi
)


(
	printf "Building %s project for iSM .....\t" "$project"
	pushd "${dir}/.."
	sh build.sh BUILDAPP ismci
	if [ $? -eq 0 ]; then
		printf "[OK]\n"
	else
		printf "[FAILED]\n"
	fi
)

echo "DONE"
