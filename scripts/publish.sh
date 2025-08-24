#!/usr/bin/env bash
set -euo pipefail
REPO_NAME=EclipzaOS
ARCH_DIR="$PWD/x86_64"

sudo pacman -S --needed --noconfirm base-devel pacman-contrib git

# pack dotfiles into a tarball that sits next to PKGBUILD
rm -f pkgs/eclipza-dotfiles/dotfiles.tar.gz
tar -C "$PWD" -czf pkgs/eclipza-dotfiles/dotfiles.tar.gz dotfiles

# build: dotfiles (deps ok), meta (no deps during build)
( cd pkgs/eclipza-dotfiles && makepkg -sfc --noconfirm )
( cd pkgs/eclipza-meta      && makepkg -f --nodeps --nocheck --noconfirm )

# collect outputs
mkdir -p "$ARCH_DIR"
find pkgs -maxdepth 2 -type f -name '*.pkg.tar.zst' -exec cp -f {} "$ARCH_DIR/" \;

# repo DB (REAL files, not symlinks)
cd "$ARCH_DIR"
repo-add -n -R "${REPO_NAME}.db.tar.zst" ./*.pkg.tar.zst
cp -f "${REPO_NAME}.db.tar.zst"    "${REPO_NAME}.db"
cp -f "${REPO_NAME}.files.tar.zst" "${REPO_NAME}.files"

# push
cd -
git add -A
git commit -m "repo: publish $(date -u +%F-%T)" || true
git push origin main
echo "Test: curl -I https://raw.githubusercontent.com/Xazirith/EclipzaOS/main/x86_64/EclipzaOS.db"
