#!/bin/bash

# === CONFIGURATION ===
USERNAME=$1
USER_HOME="/home/$USERNAME"
WEB_ROOT="$USER_HOME/public_html"
APACHE_ALIAS_CONF="/etc/httpd/conf.d/user_sites.conf"

# === Check for username as parameter ===
if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# === Create user if it doesn't exist ===
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
else
    sudo useradd -m "$USERNAME"
    echo "User '$USERNAME' created."
fi

# === Create public_html directory ===
sudo mkdir -p "$WEB_ROOT"
sudo chmod 755 "$WEB_ROOT"
sudo chown "$USERNAME:$USERNAME" "$WEB_ROOT"

# === Create a basic index.html file ===
echo "<h1>Hello from $USERNAME!</h1>" | sudo tee "$WEB_ROOT/index.html" > /dev/null
sudo chown "$USERNAME:$USERNAME" "$WEB_ROOT/index.html"

# === Configure Apache alias ===
if ! grep -q "/$USERNAME" "$APACHE_ALIAS_CONF" 2>/dev/null; then
    echo "
Alias /$USERNAME $WEB_ROOT
<Directory $WEB_ROOT>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
" | sudo tee -a "$APACHE_ALIAS_CONF" > /dev/null
    echo "Apache alias for /$USERNAME created."
else
    echo "Apache alias for /$USERNAME already exists."
fi

# === Secure home directory for SFTP (chroot requires root-owned home) ===
sudo chown root:root "$USER_HOME"
sudo chmod 755 "$USER_HOME"

# === Configure SFTP-only access ===
SSHD_CONFIG="/etc/ssh/sshd_config"
if ! sudo grep -q "Match User $USERNAME" "$SSHD_CONFIG"; then
    echo "
Match User $USERNAME
    ForceCommand internal-sftp
    ChrootDirectory $USER_HOME
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication no
" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    echo "SFTP-only configuration added for $USERNAME."
else
    echo "SFTP config for $USERNAME already exists."
fi

# === Generate SSH key pair ===
SSH_DIR="$USER_HOME/.ssh"
PRIVATE_KEY="./${USERNAME}_sftp_key"

if [ ! -f "$PRIVATE_KEY" ]; then
    sudo mkdir -p "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"
    sudo ssh-keygen -t rsa -b 2048 -f "$PRIVATE_KEY" -N "" -C "$USERNAME-key"
    sudo cp "${PRIVATE_KEY}.pub" "$SSH_DIR/authorized_keys"
    sudo chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
    sudo chmod 600 "$SSH_DIR/authorized_keys"
    echo "🔐 SSH key pair generated for $USERNAME"
else
    echo "SSH key for $USERNAME already exists."
fi

# === Restart services ===
sudo systemctl restart sshd
sudo systemctl reload httpd

# === Display info ===
echo "======================================"
echo "🔐 Private key for $USERNAME:"
sudo cat "$PRIVATE_KEY"
echo ""
echo "💾 Saved to: $PRIVATE_KEY"
echo "======================================"
echo "✅ User '$USERNAME' is set up with web folder and SFTP access."
echo "🌐 Access site at: http://<your-server-ip>/$USERNAME"
echo "📂 Upload files using:"
echo "  sftp -i $PRIVATE_KEY $USERNAME@<your-server-ip>"
echo "  cd public_html"

