#!/usr/bin/env bash


systemctl start NetworkManager > /dev/null 2>&1

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

		clear
	
	fi
}




# Initializing keys, setting pacman and installing wget
get_keys(){
	P_DOWNLOADS=$(grep "ParallelDownloads" /etc/pacman.conf)
	P_SIGLEVEL=$(grep -iE "^SIGLEVEL" /etc/pacman.conf)
	awk -v initial_download="$P_DOWNLOADS" -v after_download="ParallelDownloads = 5" -v initial_siglevel="$P_SIGLEVEL" -v after_siglevel="SigLevel    = Never" '{sub(initial_download, after_download); sub(initial_siglevel, after_siglevel); print}' /etc/pacman.conf > copy.pacman
	rm /etc/pacman.conf
	cp copy.pacman /etc/pacman.conf
	rm copy.pacman
	pacman-key --init
	wait
	pacman --noconfirm -Sy archlinux-keyring
	pacman --noconfirm -S wget
}


# Selecting the disk to install on

disks(){

	OPT=$(whiptail --title "Disks" --inputbox "Choose an option(1/2/3/4....) with the disk to install to:\\n$(lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl -s ")   " ) \\nPlease be careful because this operation is not reversible." 10 60 3>&1 1>&2 2>&3 3>&1 )
	OPTIONS=$(lsblk -d -n | grep -v "loop" | awk '{print $1, $4}' | nl | awk '{print $1}')
	clear
}

# Creating partitions
partitioning(){
if [[ -n $(echo $OPTIONS | grep $OPT 2>/dev/null) ]]; then

        DISK=$(lsblk -d -n | grep -v "loop" | awk '{print $1}' | awk ' NR == '$OPT' {print }')

        if [[ -n $(ls /sys/firmware/efi/efivars 2>/dev/null) ]];then

                MODE="UEFI"

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


                MODE="BIOS"

        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << FDISK_CMDS | fdisk /dev/$DISK
o      # create new MBR partition
n      # add new partition
       # partition type
       # partition number
       # default - first sector
+4G    # partition size
y      # to remove signature if it is the case
       # if there is a need to press enter
       # if there is a need to press enter
n      # add new partition
       # partition type
       # partition number
       # default - first sector
+30G   # default - last sector
y      # if there is a need to press enter
       # if there is a need to press enter
       # if there is a need to press enter
n      # change partition type
       # partition number
       # default - first sector
       # default - last sector
y      # to remove signature if it is the case
       # if there is a need to press enter
       # if there is a need to press enter
t      # if there is a need to press enter
1      # if there is a need to press enter
swap   # if there is a need to press enter
       # if there is a need to press enter
       # if there is a need to press enter
w      # write partition table and exit
FDISK_CMDS

        fi

else
        echo "Wrong option."
        exit 1
fi

}


# Formatting partitions
formatting(){

	PARTITIONS=$(lsblk -l -n | grep "$DISK" | tail -n +2 | awk '{print $1}')

	if [[ $MODE == "UEFI" ]]; then

		BOOT_P=$(echo "$PARTITIONS" | head -n1)

		HOME_P=$(echo "$PARTITIONS" | tail -n1)

		ROOT_P=$(echo "$PARTITIONS" | grep -v "$BOOT_P\|$HOME_P")

		mkfs.fat -F32 $(echo "/dev/$BOOT_P")
		mkfs.ext4 -F $(echo "/dev/$ROOT_P")
		mkfs.ext4 -F $(echo "/dev/$HOME_P")

	elif [[ $MODE == "BIOS" ]]; then

		SWAP_P=$(echo "$PARTITIONS" | head -n1)

		HOME_P=$(echo "$PARTITIONS" | tail -n1)

		ROOT_P=$(echo "$PARTITIONS" | grep -v "$SWAP_P\|$HOME_P")

		mkswap $(echo "/dev/$SWAP_P")
		mkfs.ext4 -F $(echo "/dev/$ROOT_P")
		mkfs.ext4 -F $(echo "/dev/$HOME_P")

	else
		echo "An error occured. Exiting..."
		exit 1
	fi
}


# Mounting partitons
mounting(){

        if [[ $MODE == "UEFI" ]]; then

                mount $(echo "/dev/$ROOT_P") /mnt

                mkdir /mnt/boot
                mount $(echo "/dev/$BOOT_P") /mnt/boot

                mkdir /mnt/home
                mount $(echo "/dev/$HOME_P") /mnt/home

        elif [[ $MODE == "BIOS" ]]; then

                mount $(echo "/dev/$ROOT_P") /mnt

                swapon $(echo "/dev/$SWAP_P")

                mkdir /mnt/home
                mount $(echo "/dev/$HOME_P") /mnt/home

        else
                echo "An error occured. Exiting..."
                exit 1
        fi
}

# Installing packages

install_packages(){
	wget $PROGS_GIT
	pacstrap -K /mnt $(tail packages.csv -n +2 | grep -v "AUR\|GIT" | awk -F ',' '{print $1}' | paste -sd' ')
}


# MAIN

main(){
	
	printf "\nJust a moment...\n\n"

	sleep 4

	check_internet

	get_keys

	disks

	partitioning

	formatting

	mounting

	install_packages

	genfstab -U /mnt >> /mnt/etc/fstab


	printf "\n\nNow entering the system.\n\nThe boot mode is: %s.\n\nTo continue with the installation process execute the script installation_script_part2.sh specifying the mode.\n\nExample\n\n$: installation_script_part2.sh BIOS\n\n$: installation_script_part2.sh UEFI\n\n" "$MODE"

	cp $(which installation_script_part2.sh) /mnt/usr/local/bin/

	arch-chroot /mnt

}


main

