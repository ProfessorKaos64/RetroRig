#!/bin/bash
#
#small script to copy over configuration files for emulators
#Version 0.6.1
#Please report any errors via a pull request
#
#
#Pre-requisite checks:
#check for dialog and prompt to install if it is not present
if ! which dialog > /dev/null; then
   echo -e "dialog command not found! Install? (y/n) \c"
   read DIALOG
   if [ $DIALOG = "y" ]; then
      sudo apt-get install dialog >> /dev/null
   elif  [ $DIALOG = "n" ]; then
	echo "exiting!"
	sleep 2s
	exit
   fi
fi

if ! which git > /dev/null; then
   echo -e "git command not found! Install? (y/n) \c"
   read GIT
   if [ $GIT = "y" ]; then
      sudo apt-get install git >> /dev/null
   elif  [ $GIT = "n" ]; then
        echo "exiting!"
        sleep 2s
        exit
   fi
fi

function _main () {
_prereq

cmd=(dialog --backtitle "LibreGeek.org RetroRig Installer" --menu "Choose your option(s). BIOS files for pcsx, pcsx2 NOT provided!" 16 70 16)
options=(1 "Install Software" 
	 2 "Set up default configuration files and init scripts" 
	 3 "Retro Rig Settings" 
	 4 "Pull latest files from git" 
	 5 "Update emulator binaries" 
	 6 "Upgrade System (use with caution!)" 
	 7 "Start RetroRig" 
	 8 "Reboot PC" 
	 9 "Exit")

	#make menu choice
	selection=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	#functions

	for choice in $selection
	do
		case $choice in
		1)  	
		_software
		_main
		;;

		2)  
		_configuration
		_main 
		;;

		3)
		_settings
		_main
		;;

		4)
		_update-git
		#reload script with changes
		bash config-setup.sh
		;;

		5)
		_update-binaries
		_main
		;;

		6)
		_upgrade-system
		_main
		;;

		7)
		_start-xbmc
		_main
		;;

		8)
		_reboot
		_main
		;;

		9)  
		clear
		exit
		;;
esac
done
}

#settings function
function _settings (){

cmd=(dialog --backtitle "LibreGeek.org RetroRig Installer" --menu "Settings Menu" 16 46 16)
options=(1 "Change resolution for emulators"  
	 2 "Back to main menu")

	#make menu choice
	selection=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	#functions

	for choice in $selection
	do
		case $choice in
		1)  	
		_resolution
		_settings
		;;

		2)  
		clear
		_main
		;;
esac
done
}

function _resolution () {

#menu
while true; do
cmd=(dialog --backtitle "RetroRig Settings" --menu "Choose your resolution" 16 32 16)
options=(1 "Current Resolution"
	 2 "1366x768 (720p)"
	 3 "Custom"
	 4 "Back to settings menu"
	 5 "Back to main menu"
	)
     
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
if [ "$choices" != "" ]; then
    case $choices in

	 1) 
		#mupen64plus
		echo "mupen64plus:" >> res.txt
		grep -i "ScreenWidth = " $HOME/.config/mupen64plus/mupen64plus.cfg >> res.txt
		grep -i "ScreenHeight = " $HOME/.config/mupen64plus/mupen64plus.cfg >> res.txt
		echo "" >> res.txt
		#ZSNES
		echo "ZSNES:" >> res.txt
		grep -i "CustomResX=" $HOME/.zsnes/zsnesl.cfg  >> res.txt
		grep -i "CustomResY=" $HOME/.zsnes/zsnesl.cfg  >> res.txt
		echo "" >> res.txt
		#report current resolution
		dialog --textbox res.txt 33 40
		#remove text file
		rm res.txt
		;; 
      
	 2) 
		clear
		dialog --infobox "Setting resolution to 1360x768 (720p)" 3 48

		########################		
		#mupen64plus
		########################

		m_org_X=$(grep -i "ScreenWidth = " $HOME/.config/mupen64plus/mupen64plus.cfg)
		m_org_Y=$(grep -i "ScreenHeight = " $HOME/.config/mupen64plus/mupen64plus.cfg)
		#set new resolution(s) from configs
		m_new_X="1366"
		m_new_Y="768"
		#make the changes, prefix new_X in case NULL was entered previousey
		#mupen64plus
		sed -i "s|$m_org_X|ScreenWidth = $m_new_X|g" $HOME/.config/mupen64plus/mupen64plus.cfg
		sed -i "s|$m_org_Y|ScreenHeight = $m_new_Y|g" $HOME/.config/mupen64plus/mupen64plus.cfg

		########################		
		#ZSNES
		######################## 

		#zsnes will not open properly if an improper resolution is set
		z_org_X=$(grep -i "CustomResX=" $HOME/.zsnes/zsnesl.cfg)
		z_org_Y=$(grep -i "CustomResY=" $HOME/.zsnes/zsnesl.cfg)
		#set new resolution(s) from configs
		z_new_X="1366"
		z_new_Y="768"
		#make the changes, prefix new_X in case NULL was entered previously
		#mupen64plus
		sed -i "s|$z_org_X|CustomResX="$z_new_X"|g" $HOME/.zsnes/zsnesl.cfg
		sed -i "s|$z_org_Y|CustomResY="$z_new_Y"|g" $HOME/.zsnes/zsnesl.cfg
		;; 

	 3) 
		dialog --infobox  "Setting resolution from user input" 3 40

		#set new resolution(s) from user input
		dialog --title "Set Custom Resolution" --inputbox "Enter Width (X)" 10 4 2> /tmp/new_X
		dialog --title "Set Custom Resolution" --inputbox "Enter Length (Y)" 10 4 2> /tmp/new_Y

		########################		
		#mupen64plus
		########################

		#grab current resolutions
		m_org_X=$(grep -i "ScreenWidth = " $HOME/.config/mupen64plus/mupen64plus.cfg)
		m_org_Y=$(grep -i "ScreenHeight = " $HOME/.config/mupen64plus/mupen64plus.cfg)
		#set new resolution(s) from configs
		m_new_X=$(cat '/tmp/new_X')
		m_new_Y=$(cat '/tmp/new_Y')
		#make the changes, prefix new_X in case NULL was entered previously
		sed -i "s|$m_org_X|ScreenWidth = "$m_new_X"|g" $HOME/.config/mupen64plus/mupen64plus.cfg
		sed -i "s|$m_org_Y|ScreenHeight = "$m_new_Y"|g" $HOME/.config/mupen64plus/mupen64plus.cfg 

		########################		
		#ZSNES
		######################## 

		#zsnes will not open properly if an improper resolution is set
		z_org_X=$(grep -i "CustomResX=" $HOME/.zsnes/zsnesl.cfg)
		z_org_Y=$(grep -i "CustomResY=" $HOME/.zsnes/zsnesl.cfg)
		#set new resolution(s) from configs
		z_new_X=$(cat '/tmp/new_X')
		z_new_Y=$(cat '/tmp/new_Y')
		#make the changes, prefix new_X in case NULL was entered previously
		#ZSNES
		sed -i "s|$z_org_X|CustomResX="$z_new_X"|g" $HOME/.zsnes/zsnesl.cfg
		sed -i "s|$z_org_Y|CustomResY="$z_new_Y"|g" $HOME/.zsnes/zsnesl.cfg

		########################		
		#Cleanup
		######################## 

		rm -f /tmp/new_X
		rm -f /tmp/new_Y

		_resolution
		;; 
	 4) 
		_settings
		return
		;;
	 5) 
		_main
		return
		;;

	 esac
     else
	 break
fi
done
}

#software function
function _software () {
	dialog --infobox "Installing required programs...Please wait" 3 48 ; sleep 3s 
	clear

	#add multi-arch support
	sudo dpkg --add-architecture i386

	#add repository for pcsx2 (PS2 emulator)
	sudo add-apt-repository -y ppa:gregory-hainaut/pcsx2.official.ppa

	#add repository for official team XBMC "stable"
	sudo add-apt-repository -y ppa:team-xbmc/ppa

	#add repository for dolphin-emu
	sudo add-apt-repository -y ppa:glennric/dolphin-emu

	#update repository listings
	sudo apt-get update

	#install software
	sudo apt-get install -y xboxdrv curl zsnes nestopia pcsxr pcsx2:i386 \
	python-software-properties pkg-config software-properties-common \
	mame mupen64plus dconf-tools qjoypad xbmc dolphin-emu-master stella \
	build-essential 

	#clear
	clear
}

#configuration function
function _configuration () {
	dialog --infobox "Seting up configuration files" 3 35 ; sleep 3s
	clear
	#disable screensaver, XBMC will manage this
	#export display to allow gsettings running in terminal window
	export DISPLAY=:0.0
	#gsettings set org.gnome.settings-daemon.plugins.power active 'false'
	#gsettings set org.gnome.desktop.screensaver idle-activation-enabled 'false'
	#gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'

	#trying gconftool to disable screen locks
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock/blank_screen false
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock/gnome_keyring_hibernate false
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock/gnome_keyring_suspend false
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock/hibernate false
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock/suspend false
	gconftool-2 --type boolean -s /apps/gnome-power-manager/lock_use_screensaver_settings true
	gconftool-2 --type boolean -s /apps/gnome-screensaver/lock_enabled false

	#setup skelton folders for XBMC Rom Collection Browser
	#ROMs
	mkdir -pv $HOME/Games/ROMs/Atari\ 2600/
	mkdir -pv $HOME/Games/ROMs/Gamecube/
	mkdir -pv $HOME/Games/ROMs/Mame4All/
	mkdir -pv $HOME/Games/ROMs/N64/
	mkdir -pv $HOME/Games/ROMs/NES/
	mkdir -pv $HOME/Games/ROMs/SNES/
	mkdir -pv $HOME/Games/ROMs/PS2/
	mkdir -pv $HOME/Games/ROMs/PS1/
	mkdir -pv $HOME/Games/ROMs/sgenroms/
	mkdir -pv $HOME/Games/ROMs/SNK\ Neo\ Geo/

	#Artwork 
	mkdir -pv $HOME/Games/Artwork/Atari\ 2600
	mkdir -pv $HOME/Games/Artwork/Gamecube
	mkdir -pv $HOME/Games/Artwork/MAME
	mkdir -pv $HOME/Games/Artwork/N64
	mkdir -pv $HOME/Games/Artwork/NESt
	mkdir -pv $HOME/Games/Artwork/SNES
	mkdir -pv $HOME/Games/Artwork/PS2
	mkdir -pv $HOME/Games/Artwork/PS1
	mkdir -pv $HOME/Games/Artwork/Genesis
	mkdir -pv $HOME/Games/Artwork/SNK\ Neo\ Geo

	#Saves (if any)
	mkdir -pv $HOME/Games/Saves/Atari\ 2600/
	mkdir -pv $HOME/Games/Saves/Gamecube/
	mkdir -pv $HOME/Games/Saves/Mame4All/
	mkdir -pv $HOME/Games/Saves/N64/
	mkdir -pv $HOME/Games/Saves/NES/
	mkdir -pv $HOME/Games/Saves/SNES/
	mkdir -pv $HOME/Games/Saves/PS2/
	mkdir -pv $HOME/Games/Saves/PS1/
	mkdir -pv $HOME/Games/Saves/genroms/
	mkdir -pv $HOME/Games/Saves/SNK\ Neo\ Geo/

	#create dotfiles
	mkdir -pv $HOME/.qjoypad3/
	mkdir -pv $HOME/.dolphin-emu/Config/
	mkdir -pv $HOME/.config/mupen64plus/
	mkdir -pv $HOME/.nestopia/
	mkdir -pv $HOME/.gens/
	mkdir -pv $HOME/.zsnes/
	mkdir -pv $HOME/.mame/cfg/
	mkdir -pv $HOME/.pcsx/plugins/
	mkdir -pv $HOME/.pcsx/patches/
	mkdir -pv $HOME/.config/pcsx2/inis/
	mkdir -pv $HOME/.stella/
	mkdir -pv $HOME/.xbmc/

	#xbmc does not (at least for Ubuntu's repo pkg) load the
	#dot files without loading XBMC at least once
	#copy in default folder base from first run:	
	cp -Rv $HOME/RetroRig/XBMC/* $HOME/.xbmc

	#xboxdrv director located in common area for startup
	echo "sudo needed to create common xboxdrv share!"
	sudo mkdir -pv /usr/share/xboxdrv/

	#Tools
	mkdir -pv $HOME/Games/Tools/

	#configs
	mkdir -pv $HOME/Games/Configs/

	#Nestopia
	#default path: /home/$USER/.nestopia
	cp -v $HOME/RetroRig/Nestopia/nstcontrols $HOME/.nestopia/
	cp -v $HOME/RetroRig/Nestopia/nstsettings $HOME/.nestopia/

	#gens
	#default path: /home/$USER/.gens
	#Global config
	cp -v $HOME/RetroRig/Gens-GS/gens.cfg $HOME/.gens/

	#ZSNES
	#default path: /home/$USER/.zsnes
	#Controller config
	cp -v $HOME/RetroRig/ZSNES/zinput.cfg $HOME/.zsnes/
	cp -v $HOME/RetroRig/ZSNES/zsnesl.cfg $HOME/.zsnes/

	#mame
	#default path: /home/$USER/.mame
	#Main config
	cp -v $HOME/RetroRig/MAME/default.cfg $HOME/.mame/cfg
	cp -v $HOME/RetroRig/MAME/mame.ini $HOME/.mame
	#offline artwork scrapper
	cp -v $HOME/RetroRig/MAME/Artwork/* $HOME/Games/Artwork/MAME	
	
	#pcsx
	#default path: /home/$USER/.pcsx
	#Main config
	cp -v $HOME/RetroRig/pcsx/pcsx.cfg $HOME/.pcsx/
	cp -Rv $HOME/RetroRig/pcsx/plugins $HOME/.pcsx/
	cp -Rv $HOME/RetroRig/pcsx/patches $HOME/.pcsx/

	#pcsx2
	#default path: /home/$USER/.config/pcsx2
	#Main config
	cp -v $HOME/RetroRig/pcsx2/PCSX2-reg.ini $HOME/.config/pcsx2/
	cp -v $HOME/RetroRig/pcsx2/inisOnePAD.ini $HOME/.config/pcsx2/
	cp -v $HOME/RetroRig/pcsx2/inis/* $HOME/.config/pcsx2/inis/

	#mupen64pluspwd
	#default path: /home/$USER/.config/mupen64plus
	#Main config
	cp -v $HOME/RetroRig/mupen64plus/mupen64plus.cfg $HOME/.config/mupen64plus/

	#Stella
	#default path: /home/$USER/.config/mupen64plus
	#Main config
	cp -v $HOME/RetroRig/Stella/stellarc $HOME/.stella/

	#dolphin
	#default path /home/$USER/.dolphin-emu/
	#emulator config
	cp -Rv /$HOME/RetroRig/Dolphin/Dolphin.ini $HOME/.dolphin-emu/Config/
	#Gamecube controller config
	cp -Rv /$HOME/RetroRig/Dolphin/GCPadNew.ini $HOME/.dolphin-emu/Config/
	#Wii controller config

	#OpenGL graphics config
	cp -Rv /$HOME/RetroRig/Dolphin/gfx_opengl.ini $HOME/.dolphin-emu/Config/

	#copy config for qjoypad setup
	cp -v $HOME/RetroRig/controller-cfg/retro-gaming.lyt $HOME/.qjoypad3/

	#add xbox controller init script
	echo "sudo needed to create init scripts for xboxdrv!"
	sudo cp -v $HOME/RetroRig/controller-cfg/xpad-wireless.xboxdrv /usr/share/xboxdrv/
	sudo cp -v $HOME/RetroRig/init-scripts/xboxdrv /etc/init.d/
	sudo update-rc.d xboxdrv defaults

	#copyautoexec.py in the userdata folder for autostarting RCB
	#cp -v $HOME/RetroRig/RCB/autoexec.py $HOME/.xbmc/userdata/

	#blacklist xpad
	echo "sudo needed to blacklist xpad!"
	sudo cp -v $HOME/RetroRig/init-scripts/blacklist.conf /etc/modprobe.d/

	#create autostart for XBMC and qjoypad
	echo "sudo needed to create auto-start entries!"
	sudo cp -v /usr/share/applications/xbmc.desktop /etc/xdg/autostart/
	sudo cp -v $HOME/RetroRig/controller-cfg/qjoypad.desktop /etc/xdg/autostart/
	#If xboxdrv config file does not pick up on reboot,
	#be sure to resync the wireless receiver!

	#set the system user to an absolute value.
	#RCB and some config files don't like using $HOME, rather /home/test/
	#Let's change the config files to reflect the current username
	new_U=$(cat'$USER')
	#change default user from config files to target user. 'first run only!!!' 
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.config/pcsx2/PCSX2-reg.ini 
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.gens/gens.cfg
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.zsnes/zsnesl.cfg
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.pcsx/pcsx.cfg 
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.dolphin-emu/Config/Dolphin.ini 
	sed -i "s|/home/test/|/home/$USER/|g" $HOME/.xbmc/userdata/addon_data/script.games.rom.collection.browser/config.xml
	
	#remind user about default resolution
	#If the default is not supported on the monitor, emulators like zsnes will fail to start!
	dialog --infobox "Default Resolution is 1360x768 (720p)! Please ensure your \
                          monitor supports this resolution, or change it in the settings menu! \
                          Main Menu > Option 3 > Option 1" 8 35 ; sleep 6s

}

function _update-git () {
	dialog --infobox "updating git repo" 4 10
	sleep 2s
	cd $HOME/RetroRig/
	git pull
	#pause for reviewing changes
	sleep 5s
	bash config-setup.sh
}

function _update-binaries () {
	echo "updating binaries"
	sudo apt-get install -y xboxdrv zsnes nestopia pcsxr pcsx2:i386\
	mame mupen64plus qjoypad xbmc dolphin-emu-master stella	
	sleep 3s
}

function _upgrade-system () {
	dialog --infobox "updating system" 3 11
	sudo apt-get update
	sudo apt-get upgrade
	sleep 3s
}

function _start-xbmc () {
	dialog --infobox "starting RetroRig" 3 24
	sleep 2s
	xbmc
}

function _reboot () {
	#need to add reboot command to sudo to avoid pw prompt
        dialog --infobox "Rebooting in 5 seconds, press CTRL+C to cancel" 3 51 ; sleep 5s
        sleep 5s
        sudo reboot 
}
#call main
_main
