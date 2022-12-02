#!/usr/bin/env bash


MODE="$1"
DISK=$(lsblk -l -n | grep "$(lsblk -l | grep "/home" | awk '{print $1}' | cut -b-3)" | head -n1 | awk '{print $1}')


# Installation script
SCRIPT="https://raw.githubusercontent.com/arghpy/suckless_progs/main/installation_script.sh"

# Programs to install
PROGS_GIT="https://raw.githubusercontent.com/arghpy/suckless_progs/main/packages.csv"

# local configuration
CONFIG_GIT="https://github.com/arghpy/local_config"


# Changing the language to english

change_language(){
	ENGLISH=$(grep "#en_US.UTF-8 UTF-8" /etc/locale.gen)
	awk -v initial="$ENGLISH" -v after="en_US.UTF-8 UTF-8" '{sub(initial, after); print}' /etc/locale.gen > copy.locale.gen
	rm /etc/locale.gen
	cp copy.locale.gen /etc/locale.gen
	rm copy.locale.gen
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

set_user() {
	NAME=$(whiptail --inputbox "Please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1

	useradd -m -g wheel -s /bin/zsh "$NAME" >/dev/null 2>&1
	usermod -a -G wheel "$NAME"
	export REPODIR="/home/$NAME/.local/src"
	mkdir -p "$REPODIR"
	chown -R "$NAME":wheel "$(dirname "$REPODIR")"
	clear
	printf "\n\nEnter password for %s\n\n" "$NAME"
	passwd $(echo "$NAME")

}



#Install yay: script taken from Luke Smith

yay_install() {
	whiptail --infobox "Installing yay, an AUR helper..." 7 50
	sudo -u "$NAME" mkdir -p "$REPODIR/yay"
	sudo -u "$NAME" git -C "$REPODIR" clone --depth 1 --single-branch \
		--no-tags -q "https://aur.archlinux.org/yay.git" "$REPODIR/yay" ||
		{
			cd "$REPODIR/yay" || return 1
			sudo -u "$NAME" git pull --force origin master
		}
	cd "$REPODIR/yay" || exit 1
	sudo -u "$NAME" -D "$REPODIR/yay" makepkg --noconfirm -si >/dev/null 2>&1 || return 1

	sudo -u "$NAME" wget $PROGS_GIT
	sudo -u "$NAME" yay --noconfirm -S $(cat packages.csv | grep "AUR" | awk -F ',' '{print $1}' | paste -sd' ')
}




# Installing grub and creating configuration

grub(){

	if [[ $MODE == "UEFI" ]]; then

		pacman --noconfirm -S grub efibootmgr
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
		grub-mkconfig -o /boot/grub/grub.cfg

	elif [[ $MODE == "BIOS" ]]; then
		
		pacman --noconfirm -S grub 
		grub-install $(echo "/dev/$DISK")
		grub-mkconfig -o /boot/grub/grub.cfg
	else
		echo "An error occured at grub step. Exiting..."
		exit 1
	fi
}


# MAIN

main(){
	pacman-key --init
	wait
	pacman -Sy
	pacman-key --populate archlinux

	ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

	hwclock --systohc

	change_language

	set_hostname

	set_user

	yay_install

	grub

	systemctl start NetworkManager

	systemctl enable NetworkManager

	echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

	XDG_DEFAULTS=$(grep -iE "^enabled" /etc/xdg/user-dirs.conf)
        awk -v initial_XDG="$XDG_DEFAULTS" -v after_XDG="enabled=False" '{sub(initial_XDG, after_XDG); print}' /etc/xdg/user-dirs.conf > copy.xdg
        rm /etc/xdg/user-dirs.conf
        cp copy.xdg /etc/xdg/user-dirs.conf
        rm copy.xdg

	sudo -u "$NAME" git clone $CONFIG_GIT
	sudo -u "$NAME" rm -rf $(echo "/home/$NAME/local_config/.git /home/$NAME/local_config/README.md")

	for i in $(grep -r "arghpy" $(echo "/home/$NAME/.*") 2>/dev/null | awk -F ':' '{print $1}'); do sed $(echo "'s@arghpy@$NAME@g'") $i | grep "$NAME"; done

	for i in $(ls -l $(echo "/home/$NAME/.local/src") | awk '{print $NF}' | grep -v "yay\|lf\|icons");do
		cd $i
		make clean install
	done

	printf "\n\nInstallation finished.\nType \`shutdown now\`, take out the installation media and boot into the new system.\n\n"
}


main

