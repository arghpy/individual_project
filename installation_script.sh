#!/usr/bin/env bash

# Installation script
SCRIPT="https://raw.githubusercontent.com/arghpy/suckless_progs/main/installation_script.sh"

# Programs to install
PROGS_GIT="https://raw.githubusercontent.com/arghpy/suckless_progs/main/packages.csv"



# Check for internet
check_internet() {

	if [[ $(ping -c1 8.8.8.8 > /dev/null 2>&1 ; echo $?) != 0 ]]; then

		whiptail --title "Internet connection"\
			 --yes-button "nmtui"\
			 --no-button "Retry"\
			 --yesno "Please check your internet connection.\\nIf your connection is through ethernet then make sure that the cable is connected.\\nIf you wish to connect thorugh wifi select 'nmtui'. Other wise select 'retry'." 10 60

		case "$(echo $?)" in
			1) nmtui ;;
			0) check_internet ;;
			*) exit 1 ;;
		esac
	
	fi
}

check_internet
