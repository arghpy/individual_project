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
				sleep 3
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




# Initializing keys, setting pacman and installing wget

get_keys(){
	P_DOWNLOADS=$(grep "ParallelDownloads" /etc/pacman.conf)
	sed -i 's|'$P_DOWNLOADS'|ParallelDownloads = 5|g' /etc/pacman.conf
	awk -v initial=$P_DOWNLOADS -v after="ParallelDownloads = 5" '{sub(initial, after); print;}' /etc/pacman.conf > /etc/pacman.conf
	pacman-key --init
	pacman --noconfirm -Sy archlinux-keyring
	pacman --noconfirm -S wget
}


# Selecting the disk to install on

disks(){
	printf "\nSelect one of the options:\n\n"
	lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl
	OPTIONS=$(lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl | awk '{print $1}')
	read OPT
}

# Creating partitions
partitioning(){
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

}

# Formatting partitions
formatting(){

	PARTITIONS=$(lsblk -l -n | grep "$DISK" | tail -n +2 | awk '{print $1}')

	BOOT_P=$(echo "$PARTITIONS" | head -n1)

	HOME_P=$(echo "$PARTITIONS" | tail -n1)

	ROOT_P=$(echo "$PARTITIONS" | grep -v "$BOOT_P\|$HOME_P")

	mkfs.fat -F32 $(echo "/dev/$BOOT_P")
	mkfs.ext4 $(echo "/dev/$ROOT_P")
	mkfs.ext4 $(echo "/dev/$HOME_P")
}


# Mounting partitons
mounting(){

	mount $(echo "/dev/$ROOT_P") /mnt

	mkdir /mnt/boot
	mount $(echo "/dev/$BOOT_P") /mnt/boot

	mkdir /mnt/home
	mount $(echo "/dev/$HOME_P") /mnt/home
}

# Installing packages

install_packages(){
	wget $PROGS_GIT
	pacstrap -K /mnt $(cat packages.csv | grep -v "AUR\|GIT" | awk -F ',' '{print $1}' | paste -sd' ')
}





# Changing the language to english

change_language(){
	ENGLISH=$(grep "#en_US.UTF-8 UTF-8" /etc/locale.gen)
	awk -v initial=$ENGLISH -v after="en_US.UTF-8 UTF-8" '{sub(initial, after); print;}' /etc/locale.gen > /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
}


# Setting the hostname

set_hostname(){
	printf "\n\nPlease enter a hostname for the system:\n\n"
	read SYS_HOSTNAME
	echo "$SYS_HOSTNAME" > /etc/hostname
}


# Get user and password: script taken from Luke Smith

getuserandpass() {
	NAME=$(whiptail --inputbox "Please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		NAME=$(whiptail --nocancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	PASS1=$(whiptail --nocancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	PASS2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$PASS1" = "$PASS2" ]; do
		unset PASS2
		PASS1=$(whiptail --nocancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		PASS2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
}


# MAIN

main(){
	
	check_internet

	get_keys

	disks

	partitioning

	formatting

	mounting

	install_packages

	genfstab -U /mnt >> /mnt/etc/fstab

	arch-chroot /mnt

	ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

	hwclock --systohc

	change_language

	getuserandpass
}


main

