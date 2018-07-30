#!/usr/bin/env bash

#
# Make sure we are not running as root.
#
if [[ $EUID -ne 0 ]]; then
   echo "Running as regular using, using sudo prompts to do administrative tasks."
else
   echo "This script must not be run as root"
   exit 1
fi

TEMP_DIR='~/tmp'
TARGET_DIR='~/bootstrap'
BIN_DIR='~/bin'
DOTFILES='~/dotfiles'
PWD=$(pwd)

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

#
# Remove bloatware
#
sudo dnf remove -y libreoffice* libreoffice-calc libreoffice-core libreoffice-data libreoffice-draw libreoffice-filters libreoffice-graphicfilter libreoffice-gtk2 libreoffice-gtk3 libreoffice-help-en libreoffice-impress libreoffice-langpack-en libreoffice-math libreoffice-opensymbol-fonts libreoffice-pdfimport libreoffice-pyuno libreoffice-ure libreoffice-ure-common libreoffice-writer libreoffice-x11 libreoffice-xsltfilter libreofficekit libreoffice-calc libreoffice-core vim-minimal evolution

#
# Update packages
#
sudo dnf update -y

#
# Default packages
#
sudo dnf install -y libicu libunwind awesome zsh compat-openssl10 util-linux-user mono-devel htop gcc-c++ make cmake openssl-libs openssl-devel p7zip vlc terminator nautilus-open-terminal dnf-utils mupdf feh byobu gnome-tweaks vim terminator util-linux-user dconf-editor mupdf feh git

#
# Create lower case folder names.
#
cd ~
rmdir Downloads
rmdir Desktop
rmdir Documents
rmdir Pictures
mkdir downloads
mkdir documents
mkdir pictures
mkdir work
mkdir $BIN_DIR
rm -rf ~/tmp
mkdir ~/tmp
cd $PWD

echo -e "${YELLOW}Enter the new hostname:${NC}"
read NEWHOSTNAME
hostnamectl set-hostname $NEWHOSTNAME

echo -e "${YELLOW}Generating new SSH key for this machine:${NC}"
mkdir -p .ssh
cd .ssh
ssh-keygen -t ed25519 -f id_ed25519_hardman
cd ..

git clone https://github.com/b0wter/dotfiles.git $DOTFILES

rm ~/.config/user-dirs.dirs
ln -s $DOTFILES/user-dirs.dirs ~/.config/user-dirs.dirs

#
# Node.js
#
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo dnf install -y nodejs
sudo npm install -g @angular/cli

#
# VS Code
#
# wget -O ~/tmp/vscode.rpm http://go.microsoft.com/fwlink/?LinkId=723968
# sudo dnf install -y ~/tmp/vscode.rpm
# TODO: VS Code Addons
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code-insiders

#
# Sublime Text
#
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install -y sublime-text
xargs -0 -n 1 code-insiders --install-extension < <(tr \\n \\0 <~/$TEMP_DIR/code_addons.txt)

#
# Microsoft Repo (Powershell, .net core)
# Installs the latest version that does not have a "rc" or "preview" in its name.
#
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
sudo dnf update
# find latest sdk version (excluding previews)
latest_sdk_version=$(dnf search dotnet-sdk | grep -v preview | grep -v rc | tail -n 1 | sed 's/\s.*$//' | tr -d '\n')
sudo dnf install -y $latest_sdk_version powershell

#
# Nativefier
#
sudo npm install nativefier -g

#
# Franz
#
wget -O $TEMP_DIR/franz https://github.com/meetfranz/franz/releases/download/v5.0.0-beta.18/franz-5.0.0-beta.18-x86_64.AppImage
chmod +x $TEMP_DIR/franz
mv $TEMP_DIR/franz $BIN_DIR

#
# Postman
#
wget -P $TEMP_DIR https://dl.pstmn.io/download/latest/linux64
sudo mkdir -p /opt/postman
sudo mv $TEMP_DIR/linux64 /opt/postman/postman

#
# Docker
#
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf config-manager --set-enabled docker-ce-edge
sudo dnf update
sudo dnf install -y docker-ce
sudo systemctl enable docker
sudo usermod -a -G docker b0wter

#
# Restore dotfiles
#
# .config/user-dirs.dirs !!
# Vim
# zshrc
# ZSH Theme (biraex)

#
# Firefox userChrome.css
#
ln -s $DOTFILES/userChrome.css $(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default*")/chrome/userChrome.css

#
# Android Studio
#
# TODO
# Goal: 
# * install Android Studio to /opt/android/android-studio
# * install Android SDK to /opt/android/sdk <-- might be tough because it is installed through the Android Studio initialization.

#
# Fish Shell
#
sudo dnf install -y fish
curl -L https://get.oh-my.fish | fish

#
# RPM Fusion
# (first two lines add repositories, third installs minimal plugins, fourth adds some extras, fifth installs additional libs for browsers)
# Details: https://ask.fedoraproject.org/en/question/9111/sticky-what-plugins-do-i-need-to-install-to-watch-movies-and-listen-to-music/
#
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y gstreamer1-{ffmpeg,libav,plugins-{good,ugly,bad{,-free,-nonfree}}} --setopt=strict=0
sudo dnf install -y gstreamer1-{plugin-crystalhd,ffmpeg,plugins-{good,ugly,bad{,-free,-nonfree,-freeworld,-extras}{,-extras}}} libmpg123 lame-libs --setopt=strict=0
sudo dnf install -y ffmpeg-libs

#
# OPTIONAL NVidia Treiver
# Too complex for scripting, see:
# https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/
#

#
# Gnome 3 Grid
# Install using the web extensions since the installation is done using the gnome tweak tool.
# Use the following command to set the workspace names:
# gsettings set org.gnome.desktop.wm.preferences workspace-names "['Messaging', 'Web', 'Misc', 'Terminal', 'Work #1', 'Work #2']"
# gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

#
# Gnome 3 DConf Settings
#
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

#
# Install fonts.
#
# Fira
mkdir -p ~/.local/share/fonts
for type in Bold Light Medium Regular Retina; do
    wget -O ~/.local/share/fonts/FiraCode-${type}.ttf \
    "https://github.com/tonsky/FiraCode/blob/master/distr/ttf/FiraCode-${type}.ttf?raw=true";
done
# Powerline
git clone https://github.com/powerline/fonts.git $TEMP_DIR/powerline
$TEMP_DIR/powerline/install.sh
rm -rf $TEMP_DIR/powerline
fc-cache -f -v

#
# Wallpaper
#
wget --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -O ~/pictures/wallpaper.jpg https://interfacelift.com/wallpaper/7yz4ma1/04128_glaciertrifecta_2560x1440.jpg
gsettings set org.gnome.desktop.background picture-uri file:///home/b0wter/pictures/wallpaper.jpg
