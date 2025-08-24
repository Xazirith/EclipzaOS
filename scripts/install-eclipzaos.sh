#!/bin/bash
# EclipzaOS Installer
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'  
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[EclipzaOS]${NC} $*"; }

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Don't run as root${NC}"
    exit 1
fi

log "Installing packages..."
sudo pacman -S --needed --noconfirm hyprland waybar wofi kitty steam

log "Setting up configs..."
mkdir -p ~/.config/hypr ~/.config/waybar

cp configs/hyprland/hyprland.conf ~/.config/hypr/
cp configs/waybar/config ~/.config/waybar/ 
cp configs/waybar/style.css ~/.config/waybar/

echo "#!/bin/bash
Hyprland" > ~/start-eclipza.sh
chmod +x ~/start-eclipza.sh

echo -e "${GREEN}Done! Start with: ~/start-eclipza.sh${NC}"
