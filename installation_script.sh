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
			0) 

				systemctl start NetworkManager > /dev/null 2>&1
				sleep 2
				nmtui 2>/dev/null
				;;
			1) 
				sleep 2
				check_internet 
				;;
			*) 
				exit 1 
				;;
		esac
	
	fi
}

check_internet



# Necessities

pacman-key --init
pacman-key --populate archlinux
pacman -Sy
pacman --noconfirm -Sy archlinux-keyring
pacman --noconfirm -S wget



# Partitioning

disks(){
	printf "\nSelect one of the options:\n\n"
	lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl
	OPTIONS=$(lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl | awk '{print $1}')
	read OPT
}

disks


if [[ -n $(echo $OPTIONS | grep $OPT 2>/dev/null) ]]; then
	
	DISK=$(lsblk -d -n | grep -v "loop" | awk '{print $1}' | awk ' NR == '$OPT' {print }')

	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << FDISK_CMDS | fdisk /dev/$DISK
g      # create new GPT partition
n      # add new partition
       # partition number
       # default - first sector 
+1G    # partition size
y      # to remove signature if it is the case
       # if there is a need to press enter
       # if there is a need to press enter
n      # add new partition
       # partition number
       # default - first sector 
+30G   # default - last sector 
y      # to remove signature if it is the case
       # if there is a need to press enter
       # if there is a need to press enter
n      # change partition type
       # partition number
       # default - first sector
       # default - last sector
y      # to remove signature if it is the case
       # if there is a need to press enter
       # if there is a need to press enter
w      # write partition table and exit
FDISK_CMDS

else
	echo "Wrong option."
	exit 1
fi









