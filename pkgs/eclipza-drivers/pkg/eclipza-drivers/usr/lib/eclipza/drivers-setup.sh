#!/usr/bin/env bash
set -euo pipefail
log(){ echo "[eclipza-drivers] $*"; }

sudo pacman -S --needed --noconfirm pciutils vulkan-tools mesa-demos || true

gpu_map="$(lspci -nnk | grep -E "VGA|3D|Display" || true)"
has_nvidia=0; has_amd=0; has_intel=0; has_vm=0
echo "$gpu_map" | grep -qi "NVIDIA" && has_nvidia=1
echo "$gpu_map" | grep -qi "AMD\|ATI" && has_amd=1
echo "$gpu_map" | grep -qi "Intel"    && has_intel=1
if lspci | grep -qiE "VirtualBox|VMware|QEMU|Hyper-V|Virtio GPU|Red Hat"; then has_vm=1; fi

# ---------- NVIDIA ----------
if (( has_nvidia )); then
  log "NVIDIA detected"
  kern="$(uname -r)"
  if [[ "$kern" =~ linux(-zen)? ]]; then
    sudo pacman -S --needed --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings || true
  else
    sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings || true
    hdr_guess="linux-headers"; [[ "$kern" == *"zen"* ]] && hdr_guess="linux-zen-headers"
    pacman -Si "$hdr_guess" >/dev/null 2>&1 && sudo pacman -S --needed --noconfirm "$hdr_guess" || true
  fi
  sudo install -Dm644 /dev/stdin /etc/modprobe.d/nvidia.conf <<'EON'
options nvidia_drm modeset=1 fbdev=1
EON
  if grep -q '^MODULES=' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
  else
    echo 'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)' | sudo tee -a /etc/mkinitcpio.conf >/dev/null
  fi
  sudo mkinitcpio -P || true
  sudo systemctl enable --now nvidia-persistenced.service 2>/dev/null || true
  sudo systemctl enable --now nvidia-powerd.service 2>/dev/null || true
  sudo install -Dm755 /dev/stdin /usr/local/bin/prime-run <<'EOP'
#!/usr/bin/env bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
exec "$@"
EOP
fi

# ---------- AMD ----------
if (( has_amd )); then
  log "AMD detected"
  sudo pacman -S --needed --noconfirm \
    mesa lib32-mesa \
    vulkan-radeon lib32-vulkan-radeon \
    libva-mesa-driver lib32-libva-mesa-driver
fi

# ---------- INTEL ----------
if (( has_intel )); then
  log "Intel detected"
  sudo pacman -S --needed --noconfirm \
    mesa lib32-mesa \
    vulkan-intel lib32-vulkan-intel \
    intel-media-driver
fi

# ---------- VMs ----------
if (( has_vm )) && (( !has_nvidia )) && (( !has_amd )) && (( !has_intel )); then
  log "Virtual GPU detected"
  sudo pacman -S --needed --noconfirm mesa
fi

log "Done. If NVIDIA changed, reboot recommended."
