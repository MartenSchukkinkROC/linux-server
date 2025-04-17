#!/bin/bash

# === CONFIGURATIE ===
USERNAME=$1
USER_HOME="/home/$USERNAME"

# APACHE related
WEB_ROOT="$USER_HOME/public_html"
APACHE_ALIAS_CONF="/etc/httpd/conf.d/user_sites.conf"

# SSH related
SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_DIR="$USER_HOME/.ssh"
PRIVATE_KEY="./${USERNAME}_sftp_key"

# === Check of er een gebruiker (student) is meegegeven als parameter ===
if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# === Maak de gebruiker aan als hij niet bestaat ===
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
else
    sudo useradd -m "$USERNAME"
    echo "User '$USERNAME' created."
fi

# === Beveilig home directory  ===
# maak root eigenaar van $USER_HOME en wijzig permissies, op deze manier
# kan de gebruiker alleen in zijn eigen $USER_HOME komen
# Dit is belangrijk voor SFTP toegang die later wordt geconfigureerd
sudo chown root:root "$USER_HOME"
sudo chmod 755 "$USER_HOME"

# === Maak de public_html directory aan voor de gebruiker ===
# maakt folder aan, stel permissies in voor owner (rwx), group (rx), other (rx) 
# en maakt gebruiker en groep eigenaar van directory
sudo mkdir -p "$WEB_ROOT"
sudo chmod 755 "$WEB_ROOT"
sudo chown "$USERNAME:$USERNAME" "$WEB_ROOT"

# === Maak een basis index.html bestand ===
# maak index.html aan met root permissies en maak gebruiker en groep eigenaar van index.html
echo "<h1>Hello from $USERNAME!</h1>" | sudo tee "$WEB_ROOT/index.html" > /dev/null
sudo chown "$USERNAME:$USERNAME" "$WEB_ROOT/index.html"

# === Configure Apache alias ===
# voeg een alias toe zodat de bestanden in public_html van de gebruiker op de webserver
# toegankelijk zijn onder /gebruiker (voegt toe aan bestand $APACHE_ALIAS_CONF)
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

# === Configureer dat de gebruiker alleen SFTP-toegang heeft ===
# voeg een "user override" toe aan sshd_config, zodat de gebruiker
# alleen gebruik kan maken van SFTP (ForceCommand internal-sftp) en niet van SSH
# en zijn $USER_HOME als root directory ziet (en niet "omhoog" kan navigeren)
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
# Genereer een SSH key pair die door de gebruiker gebruikt kan worden voor 
# zijn SFTP-connectie (gebruik wachtwoord is niet toegestaan)
# kopieer de public key naar het bestand authorized_keys in de .ssh folder van de gebruiker
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
# Herstart SSH en Apache zodat wijzigingen ook direct van toepassing zijn
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

