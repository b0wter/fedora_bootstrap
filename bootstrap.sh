#!/usr/bin/env bash

#
# Make sure we are not running as root.
#
if [[ $EUID -ne 0 ]]; then
   echo "Running as regular using, using sudo prompts to do administrative tasks."
else
   echo "This script must not be run as root."
   exit 1
fi

# Any subsequent commands which fail will cause the shell script to exit immediately.

# Folder to store temporary downloads and files.
TEMP_DIR=$(echo $HOME/tmp)
# Folder to store this script.
TARGET_DIR=$(echo $HOME/bootstrap)
# Folder containing binary files and links to executables.
BIN_DIR=$(echo $HOME/bin)
# Folder containing all relevant config files.
DOTFILES=$(echo $HOME/dotfiles)
# Current directory.
PWD=$(pwd)
# Store name of current user.
USERNAME=$(whoami)
# Keygen method for ssh keys:
SSH_KEYGEN=ed25519

#
# --- Colors for echo <3 ---
#
NC='\e[0m' # No Color
WHITE='\e[1;37m'
BLACK='\e[0;30m'
BLUE='\e[0;34m'
LIGHT_BLUE='\e[1;34m'
GREEN='\e[0;32m'
LIGHT_GREEN='\e[1;32m'
CYAN='\e[0;36m'
LIGHT_CYAN='\e[1;36m'
RED='\e[0;31m'
LIGHT_RED='\e[1;31m'
PURPLE='\e[0;35m'
LIGHT_PURPLE='\e[1;35m'
COLOR_BROWN='\e[0;33m'
YELLOW='\e[1;33m'
GRAY='\e[0;30m'
LIGHT_GRAY='\e[0;37m'

# Perform a sudo dummy command for the user prompt.
sudo tail /proc/cpuinfo > /dev/null

# Read a hostname from the terminal (to set the hostname and generate a ssh keypair).
echo -e "${BLUE}Enter the new hostname:${NC}"
read NEWHOSTNAME
hostnamectl set-hostname $NEWHOSTNAME
# Generate a new ssh keypair for this machine.
echo -e "${BLUE}Generating new SSH key for this machine:${NC}"
mkdir -p ~/.ssh
cd ~/.ssh
ssh-keygen -t $SSH_KEYGEN -f id_ed25519_$NEWHOSTNAME
ln -s id_${SSH_KEYGEN}_${HOSTNAME} id_default
ln -s id_${SSH_KEYGEN}_${HOSTNAME}.pub id_default.pub
cd -

#
# Remove bloatware
#
echo -e "${YELLOW}${NC}"
echo -e "${YELLOW}Removing unnecessary packages.${NC}"
sudo dnf remove -y \
    evolution \
    libreoffice* \
    libreoffice-calc \
    libreoffice-core \
    libreoffice-data \
    libreoffice-draw \
    libreoffice-filters \
    libreoffice-graphicfilter \
    libreoffice-gtk2 \
    libreoffice-gtk3 \
    libreoffice-help-en \
    libreoffice-impress \
    libreoffice-langpack-en \
    libreoffice-math \
    libreoffice-opensymbol-fonts \
    libreoffice-pdfimport \
    libreoffice-pyuno \
    libreoffice-ure \
    libreoffice-ure-common \
    libreoffice-writer \
    libreoffice-x11 \
    libreoffice-xsltfilter \
    libreofficekit \
    vim-minimal \

#
# Update packages
#
echo -e "${YELLOW}Updating the installed packages.${NC}"
sudo dnf update -y

#
# Default packages
#
echo -e "${YELLOW}Installing new packages.${NC}"
sudo dnf install -y \
    android-tools \
    awesome \
    byobu \
    cmake \
    compat-openssl10 \
    dconf-editor \
    dnf-utils \
    feh \
    gcc-c++ \
    git \
    gnome-tweaks \
    htop \
    libicu \
    libunwind \
    make \
    mono-devel \
    mupdf \
    nautilus-open-terminal \
    openssl-libs \
    openssl-devel \
    p7zip \
    snapd \
    terminator \
    util-linux-user \
    vim \
    zsh

#
# Create lower case folder names.
#
echo -e "${YELLOW}Remove old default folders and create new ones.${NC}"
cd ~
rmdir Downloads
mkdir -p downloads
rmdir Documents
mkdir -p documents
rmdir Pictures
mkdir -p pictures
mkdir -p $BIN_DIR
mkdir -p work
rmdir Desktop
rm -rf ~/tmp
mkdir -p ~/tmp
cd $PWD

#
# Dotfiles
#
echo -e "${YELLOW}Cloning and referencing dotfiles.${NC}"
git clone https://github.com/b0wter/dotfiles.git $DOTFILES
# User dir names for X
rm ~/.config/user-dirs.dirs
ln -s $DOTFILES/user-dirs.dirs ~/.config/user-dirs.dirs
# vimrc
ln -s $DOTFILES/vimrc ~/.vimrc
# terminator
mkdir -o $HOME/.config/terminator
ln -s $DOTFILES/terminator_config ~/.config/terminator/config
# ssh config
chmod 600 $DOTFILES/ssh_config
cd ~/.ssh/
ln -s $DOTFILES/ssh_config config
cd -
# userChrome for Firefox tab bar
firefox -CreateProfile default
mkdir -p $(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default*")/chrome
ln -s $DOTFILES/userChrome.css $(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default*")/chrome/userChrome.css

#
# Node.js
#
echo -e "${YELLOW}Installing nodejs from the official repo.${NC}"
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo dnf install -y nodejs
sudo npm install -g @angular/cli

#
# VS Code
#
echo -e "${YELLOW}Installing VS Code${NC}"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf update

sudo dnf install -y code
# xargs -0 -n 1 code --install-extension < <(tr \\n \\0 <$TARGET_DIR/code_addons.txt)
# Disable script exit on error for the installation of vs code addons.
set +e
while read line; do code --install-extension "$line"; done <$TARGET_DIR/code_addons.txt
set -e

#
# Sublime Text
#
echo -e "${YELLOW}Installing Sublime Text${NC}"
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install -y sublime-text

#
# Microsoft Repo (Powershell, .net core)
# Installs the latest version that does not have a "rc" or "preview" in its name.
#
echo -e "${YELLOW}Installing dotnet sdk and powershell.${NC}"
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
sudo dnf update
# find latest sdk version (excluding previews)
latest_sdk_version=$(dnf search dotnet-sdk | grep -v preview | grep -v rc | tail -n 1 | sed 's/\s.*$//' | tr -d '\n')
sudo dnf install -y $latest_sdk_version powershell

#
# Nativefier
#
echo -e "${YELLOW}Installing Nativefier.${NC}"
sudo npm install nativefier -g
nativefier -n soundcloud https://soundcloud.com
sudo mv soundcloud-linux-x64/ /opt/soundcloud
ln -s /opt/soundcloud/soundcloud $BIN_DIR/soundcloud
#
# Franz
#
echo -e "${YELLOW}Installing Franz.${NC}"
wget -O $TEMP_DIR/franz https://github.com/meetfranz/franz/releases/download/v5.0.0-beta.18/franz-5.0.0-beta.18-x86_64.AppImage
chmod +x $TEMP_DIR/franz
mv $TEMP_DIR/franz $BIN_DIR

#
# Postman
#
echo -e "${YELLOW}Installing Postman.${NC}"
sudo snap install postman
# wget -P $TEMP_DIR https://dl.pstmn.io/download/latest/linux64
# sudo mkdir -p /opt/postman
# sudo mv $TEMP_DIR/linux64 /opt/postman/postman

#
# Docker
#
echo -e "${YELLOW}Installing Docker using the official repo.${NC}"
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf config-manager --set-enabled docker-ce-edge
sudo dnf update -y
sudo dnf install -y docker-ce
sudo systemctl enable docker
sudo usermod -a -G docker b0wter

#
# Android Studio
#
# TODO
# Goal: 
# * install Android Studio to /opt/android/android-studio
# * install Android SDK to /opt/android/sdk <-- might be tough because it is installed through the Android Studio initialization.
#
# Snap version is currently broken for Fedora.

#
# Spotify
#
echo -e "${YELLOW}Installing Spotify.${NC}"
sudo snap install spotify
#
# Fish Shell
#
echo -e "${YELLOW}Installing fish shell.${NC}"
sudo dnf install -y fish
git clone https://github.com/oh-my-fish/oh-my-fish ~/oh-my-fish
cd ~/oh-my-fish
bin/install --offline --noninteractive
cd -
rm -rf ~/oh-my-fish
sudo chsh -s /usr/bin/fish $USERNAME

#
# RPM Fusion
# (first two lines add repositories, third installs minimal plugins, fourth adds some extras, fifth installs additional libs for browsers)
# Details: https://ask.fedoraproject.org/en/question/9111/sticky-what-plugins-do-i-need-to-install-to-watch-movies-and-listen-to-music/
#
echo -e "${YELLOW}Installing multi media codecs.${NC}"
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y gstreamer1-{ffmpeg,libav,plugins-{good,ugly,bad{,-free,-nonfree}}} --setopt=strict=0
sudo dnf install -y gstreamer1-{plugin-crystalhd,ffmpeg,plugins-{good,ugly,bad{,-free,-nonfree,-freeworld,-extras}{,-extras}}} libmpg123 lame-libs --setopt=strict=0
sudo dnf install -y ffmpeg-libs vlc

#
# Gnome 3 Grid
# Install using the web extensions since the installation is done using the gnome tweak tool.
# Use the following command to set the workspace names:
echo -e "${YELLOW}Adjusting settings for the Gnome Grid Extension.${NC}"
gsettings set org.gnome.desktop.wm.preferences workspace-names "['Messaging', 'Web', 'Misc', 'Terminal', 'Work #1', 'Work #2']"
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

#
# Gnome 3 DConf Settings
#
echo -e "${YELLOW}Editing Gnome 3 settings.${NC}"
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 11'
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.calendar show-weekdate true

#
# Install fonts.
#
# Fira
echo -e "${YELLOW}Install Fira Code fonts.${NC}"
mkdir -p ~/.local/share/fonts
for type in Bold Light Medium Regular Retina; do
    wget -O ~/.local/share/fonts/FiraCode-${type}.ttf \
    "https://github.com/tonsky/FiraCode/blob/master/distr/ttf/FiraCode-${type}.ttf?raw=true";
done
# Powerline
echo -e "${YELLOW}Install powerline fonts.${NC}"
git clone https://github.com/powerline/fonts.git $TEMP_DIR/powerline
$TEMP_DIR/powerline/install.sh
rm -rf $TEMP_DIR/powerline
fc-cache -f -v

#
# Wallpaper
#
echo -e "${YELLOW}Setting new wallpaper.${NC}"
wget --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -O ~/pictures/wallpaper.jpg https://interfacelift.com/wallpaper/7yz4ma1/04128_glaciertrifecta_2560x1440.jpg
gsettings set org.gnome.desktop.background picture-uri file:///home/b0wter/pictures/wallpaper.jpg

#
# Remove this bootstrap folder.
#
echo -e "${YELLOW}Script finished, cleaning up.${NC}"
cd $PWD
rm -rf $TEMP_DIR
rm -rf $TARGET_DIR
echo -e "$(tput bold)Things that need to be done:$(tput sgr0)"
echo "- add the new ssh key to VSTS/Github/whatever"
echo "- install Gnome 3 Grid extension"
echo "- [ install Nvidia drivers ]"
echo
echo -e "${RED}Since the update most likely installed a new kernel module and some user relevant settings were adjusted it's recommended to restart the system.${NC}"

#
# OPTIONAL: Nvidia drivers
# Too complex for scripting, see:
# https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/
#
