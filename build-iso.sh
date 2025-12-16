#!/bin/bash
# Lurin OS ISO Builder (Fixed)

set -e

# ===== CONFIG =====
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="/tmp/lurin-build"
# Куда складывать готовый ISO (совпадает с README/документацией)
OUTPUT="$HOME/lurin-iso"
ARCHISO_TMP="/tmp/archiso-tmp"

# ===== CHECK ROOT =====
if [ "$EUID" -ne 0 ]; then
    echo "❌ Run this script with sudo"
    exit 1
fi

echo "🔧 Building Lurin OS ISO..."
echo ""

# ===== DEPENDENCIES =====
echo "📦 Installing dependencies..."
pacman -Sy --needed --noconfirm archiso imagemagick sox git

# ===== CLEAN =====
rm -rf "$WORKDIR" "$ARCHISO_TMP"
mkdir -p "$OUTPUT"

# ===== BASE PROFILE =====
echo "📁 Copying ArchISO base profile..."
cp -r /usr/share/archiso/configs/releng "$WORKDIR"

# ===== ENABLE MULTILIB IN PROFILE PACMAN.CONF =====
echo "📝 Enabling multilib in ISO pacman.conf..."
sed -i 's/#\[multilib\]/[multilib]/' "$WORKDIR/pacman.conf" || true
sed -i 's/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' "$WORKDIR/pacman.conf" || true

# ===== PACKAGES =====
echo "📦 Adding Lurin OS packages..."
cat >> "$WORKDIR/packages.x86_64" << 'EOF'

# --- Lurin OS Gaming Stack ---
steam
wine-staging
winetricks
vulkan-icd-loader
vulkan-tools
lib32-vulkan-icd-loader
lib32-mesa
lib32-nvidia-utils
gamemode
lib32-gamemode
mangohud
lib32-mangohud

# --- Audio ---
pulseaudio
pulseaudio-alsa
pavucontrol

# --- Utilities ---
git
wget
curl
htop
fastfetch
firefox

# --- Fonts ---
ttf-dejavu
ttf-liberation
noto-fonts
noto-fonts-emoji

# --- Hyprland (Wayland) setup ---
hyprland
waybar
alacritty
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
seatd
greetd
ttf-jetbrains-mono
EOF

# ===== FILESYSTEM =====
echo "📁 Preparing filesystem..."
mkdir -p "$WORKDIR/airootfs"/{usr/share/backgrounds,usr/share/sounds/lurin,usr/share/pixmaps,usr/local/bin,etc/skel/.config/neofetch}

# ===== WALLPAPERS =====
if [ -d "$PROJECT_DIR/wallpapers" ]; then
    echo "🖼️  Copying wallpapers..."
    cp "$PROJECT_DIR"/wallpapers/*.{jpg,png} "$WORKDIR/airootfs/usr/share/backgrounds/" 2>/dev/null || true
fi

# ===== SOUNDS =====
if [ -d "$PROJECT_DIR/sounds" ]; then
    echo "🔊 Copying sounds..."
    cp "$PROJECT_DIR"/sounds/*.wav "$WORKDIR/airootfs/usr/share/sounds/lurin/" 2>/dev/null || true
fi

# ===== LOGO =====
if [ -f "$PROJECT_DIR/branding/lurin-logo.png" ]; then
    echo "🎨 Copying logo..."
    cp "$PROJECT_DIR/branding/lurin-logo.png" "$WORKDIR/airootfs/usr/share/pixmaps/lurin.png"
fi

# ===== INSTALLER =====
if [ -f "$PROJECT_DIR/lurininstall" ]; then
    echo "💾 Installing installer..."
    cp "$PROJECT_DIR/lurininstall" "$WORKDIR/airootfs/usr/local/bin/"
    chmod +x "$WORKDIR/airootfs/usr/local/bin/lurininstall"
else
    echo "⚠️  Installer script 'lurininstall' not found in project root, ISO will be built without it."
fi

# ===== BASHRC =====
if [ -f "$PROJECT_DIR/configs/bashrc" ]; then
    cp "$PROJECT_DIR/configs/bashrc" "$WORKDIR/airootfs/etc/skel/.bashrc"
fi

# ===== ROOT WELCOME =====
cat > "$WORKDIR/airootfs/root/.zprofile" << 'EOF'
clear
echo -e "\033[38;2;33;150;243m"
cat << 'LOGO'
██╗     ██╗   ██╗██████╗ ██╗███╗   ██╗
██║     ██║   ██║██╔══██╗██║████╗  ██║
██║     ██║   ██║██████╔╝██║██╔██╗ ██║
██║     ██║   ██║██╔══██╗██║██║╚██╗██║
███████╗╚██████╔╝██║  ██║██║██║ ╚████║
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
LOGO
echo -e "\033[0m"
echo "🎮 Welcome to Lurin OS Live!"
echo ""
echo "Run: lurininstall"
EOF

# ===== OS-RELEASE =====
cat > "$WORKDIR/airootfs/etc/os-release" << 'EOF'
NAME="Lurin OS"
PRETTY_NAME="Lurin OS Gaming Edition"
ID=lurin
ID_LIKE=arch
BUILD_ID=rolling
EOF

# ===== PROFILEDEF =====
echo "📝 Updating ISO metadata..."
sed -i 's/^iso_name=.*/iso_name="lurin"/' "$WORKDIR/profiledef.sh"
sed -i 's/^iso_label=.*/iso_label="LURIN_OS"/' "$WORKDIR/profiledef.sh"
sed -i 's/^iso_publisher=.*/iso_publisher="Lurin OS"/' "$WORKDIR/profiledef.sh"
sed -i 's/^iso_application=.*/iso_application="Lurin OS Gaming Edition"/' "$WORKDIR/profiledef.sh"

# ===== BUILD =====
echo ""
echo "🔨 Building ISO (10–20 minutes)..."
mkarchiso -v -w "$ARCHISO_TMP" -o "$OUTPUT" "$WORKDIR"

# ===== DONE =====
echo ""
echo "✅ Lurin OS ISO ready!"
echo "📀 Output directory: $OUTPUT"
ls "$OUTPUT"

