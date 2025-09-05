#!/usr/bin/env bash
set -euo pipefail

banner() {
cat <<'EOF'
 ___       __   ________      ___    ___ ________  ________  ________ 
|\  \     |\  \|\   __  \    |\  \  /  /|\   __  \|\   ___ \|\  _____\
\ \  \    \ \  \ \  \|\  \   \ \  \/  / | \  \|\  \ \  \_|\ \ \  \__/ 
 \ \  \  __\ \  \ \   __  \   \ \    / / \ \   ____\ \  \ \\ \ \   __\
  \ \  \|\__\_\  \ \  \ \  \   \/  /  /   \ \  \___|\ \  \_\\ \ \  \_|
   \ \____________\ \__\ \__\__/  / /      \ \__\    \ \_______\ \__\ 
    \|____________|\|__|\|__|\___/ /        \|__|     \|_______|\|__| 
                            \|___|/                                   
EOF
}

echo "[*] Starting installation of required tools..."

# Detect package manager
if command -v apt-get &>/dev/null; then
  PM="apt-get"
  INSTALL="sudo apt-get install -y"
  UPDATE="sudo apt-get update"
elif command -v dnf &>/dev/null; then
  PM="dnf"
  INSTALL="sudo dnf install -y"
  UPDATE="sudo dnf check-update"
else
  echo "[-] Unsupported package manager. Please install dependencies manually."
  exit 1
fi

# Update repositories
echo "[*] Updating package repositories..."
$UPDATE

# Install core tools
echo "[*] Installing curl, grep, xargs, tr, awk, sed, poppler-utils..."
$INSTALL curl grep xargs coreutils gawk sed poppler-utils

# Check if uro is installed, if not install it
if ! command -v uro &>/dev/null; then
  echo "[*] Installing uro (URL decoder)..."
  # Try to install uro via cargo if available
  if command -v cargo &>/dev/null; then
    cargo install uro
  else
    # fallback to manual download for uro binary
    echo "[!] 'cargo' not found, downloading uro binary..."
    ARCH=$(uname -m)
    URL="https://github.com/fhanau/uro/releases/latest/download/uro-x86_64-unknown-linux-gnu.tar.gz"
    TMPDIR=$(mktemp -d)
    curl -L "$URL" -o "$TMPDIR/uro.tar.gz"
    tar -xzf "$TMPDIR/uro.tar.gz" -C "$TMPDIR"
    sudo mv "$TMPDIR/uro" /usr/local/bin/
    rm -rf "$TMPDIR"
    echo "[*] uro installed to /usr/local/bin/uro"
  fi
else
  echo "[*] uro already installed."
fi

echo "[✓] All required tools installed successfully."

banner

