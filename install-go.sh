#!/bin/bash

# ========================
# VPS Setup Script
# ========================

# CONFIGURABLE
GO_VERSION="1.22.2"
GO_TARBALL="go$GO_VERSION.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/$GO_TARBALL"

# ========= Update system =========
echo "🔄 Updating package lists..."
sudo apt update

# ========= Install NGINX =========
echo "📦 Installing NGINX..."
sudo apt install -y nginx

# ========= Configure UFW =========
echo "🛡️  Configuring UFW firewall..."
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ========= Remove old Go if exists =========
echo "🧹 Removing old Go installation..."
sudo rm -rf /usr/local/go

# ========= Download and install Go =========
echo "⬇️  Downloading Go $GO_VERSION..."
wget -q --show-progress $GO_URL

echo "📂 Extracting and installing Go..."
sudo tar -C /usr/local -xzf $GO_TARBALL
rm $GO_TARBALL

# ========= Set environment variables =========
echo "🛠️  Setting Go environment..."
SHELL_CONFIG="$HOME/.bashrc"
if [[ $SHELL == *zsh ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
fi

{
  echo ""
  echo "# Go environment"
  echo "export PATH=\$PATH:/usr/local/go/bin"
  echo "export GOPATH=\$HOME/go"
  echo "export PATH=\$PATH:\$GOPATH/bin"
} >> "$SHELL_CONFIG"

source "$SHELL_CONFIG"

# ========= Create Go workspace =========
echo "📁 Creating Go workspace..."
mkdir -p "$HOME/go/"{bin,src,pkg}

# ========= Final checks =========
echo "✅ Setup complete!"
echo ""
echo "Go version installed:"
go version
echo ""
echo "UFW status:"
sudo ufw status
