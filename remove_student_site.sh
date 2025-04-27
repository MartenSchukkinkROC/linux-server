#!/bin/bash

# === CONFIGURATIE ===
USERNAME=$1
DELETE_USER=$2  # Tweede argument: 'delete' = gebruiker verwijderen
USER_HOME="/home/$USERNAME"
WEB_ROOT="$USER_HOME/public_html"
APACHE_ALIAS_CONF="/etc/httpd/conf.d/user_sites.conf"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_DIR="/root/user_backups"

# === Stop wanneer geen gebruiker (student) is meegegeven als parameter ===
if [ -z "$USERNAME" ]; then
    echo "Gebruik: $0 <gebruikersnaam> [delete]"
    echo " - Voeg 'delete' toe als je ook de gebruiker wilt verwijderen."
    exit 1
fi

# === Stop wanneer de gebruiker niet bestaat ===
if ! id "$USERNAME" &>/dev/null; then
    echo "⚠️  Gebruiker '$USERNAME' bestaat niet."
    exit 1
fi

# === Verwijder Apache configuratie ===
# Zoek met sed regels in Apache alias configfile op basis van 
# reguliere expressie en verwijder deze
# Zie create_student_site.sh voor definitie regels
if grep -q "/$USERNAME" "$APACHE_ALIAS_CONF"; then
    WEB_ROOT_ESCAPED=$(echo "$WEB_ROOT" | sed 's_/_\\/_g')
    sudo sed -i "/Alias \/$USERNAME /d; /<Directory $WEB_ROOT_ESCAPED>/,/<\/Directory>/d" "$APACHE_ALIAS_CONF"
    echo "🗑️  Apache alias verwijderd."
else
    echo "ℹ️  Geen Apache alias gevonden."
fi

# === Verwijder SFTP configuratie ===
# Zoek met sed regel voor gebruiker in SSH configfile op basis van 
# reguliere expressie en verwijder deze en volgende 5 regels
if grep -q "Match User $USERNAME" "$SSHD_CONFIG"; then
    sudo sed -i "/Match User $USERNAME/,+5d" "$SSHD_CONFIG"
    echo "🗑️  SFTP configuratie verwijderd."
else
    echo "ℹ️  Geen SFTP configuratie gevonden."
fi

# === Alleen verwijderen als 'delete' is opgegeven als tweede optie ===
if [ "$DELETE_USER" == "delete" ]; then
    echo "👤 Controle of '$USERNAME' veilig verwijderd kan worden..."

    # Check UID (User ID)
    USER_UID=$(id -u "$USERNAME")

    # Check of gebruiker lid is van de 'wheel' groep of een systeem UID heeft
    if id "$USERNAME" | grep -q "wheel"; then
        echo "⚠️ '$USERNAME' is lid van 'wheel' groep (admin). Gebruiker wordt NIET verwijderd, alleen configuraties en home folder worden opgeruimd."
    elif [ "$USER_UID" -lt 1000 ]; then
        echo "⚠️ '$USERNAME' heeft systeem UID ($USER_UID). Gebruiker wordt NIET verwijderd, alleen configuraties en home folder worden opgeruimd."
    else
        echo "✅ '$USERNAME' is geen kritieke gebruiker. Verwijderen..."

        #Maak backup van home directory
        sudo mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$BACKUP_DIR/${USERNAME}_backup_$TIMESTAMP.tar.gz"

        echo "📦 Backup maken van $USER_HOME naar $BACKUP_FILE..."
        sudo tar czf "$BACKUP_FILE" "$USER_HOME"
        # Verwijder gebruiker
        sudo userdel "$USERNAME"
        # Verwijder de home directory van de gebruiker
        if [ -d "$USER_HOME" ]; then
            echo "🧹 Verwijderen van home directory $USER_HOME..."
            sudo rm -rf "$USER_HOME"
        fi
    fi

    echo "✅ Configuraties opgeruimd voor '$USERNAME'."
else
    echo "🚫 Gebruiker '$USERNAME' NIET verwijderd (alleen configuraties opgeruimd)."
fi

# === Herstart Apache en SSH ===
# Herstart SSH en Apache zodat wijzigingen ook direct van toepassing zijn
sudo systemctl reload httpd
sudo systemctl restart sshd

echo "✅ Verwijderen afgerond voor '$USERNAME'. Backup staat op $BACKUP_FILE."
