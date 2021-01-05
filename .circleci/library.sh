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
