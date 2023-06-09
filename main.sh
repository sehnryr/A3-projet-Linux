#!/bin/bash

SERVER_USER="ymeloi25"
SERVER_IP="10.30.48.100"
SAVES_DIR="/home/saves"

SMTP_SERVER="$1"
SMTP_LOGIN=$(echo "$2" | sed 's/@/%40/g')
SMTP_PASSWORD=$(echo "$3" | sed 's/\@/%40/g' | sed 's/\$/\\\$/g' | sed 's/\&/\\\&/g' | sed 's/\!/\\\!/g' | sed 's/\ /\\\ /g')

SENDER_EMAIL="$4"

# Verification de la validité du serveur SMTP
if [ -z "$SMTP_SERVER" ]; then
    echo "Adresse du serveur SMTP invalide"
    exit 1
fi

# Verification de la validité du login SMTP
if [ -z "$SMTP_LOGIN" ]; then
    echo "Login SMTP invalide"
    exit 1
fi

# Verification de la validité du mot de passe SMTP
if [ -z "$SMTP_PASSWORD" ]; then
    echo "Mot de passe SMTP invalide"
    exit 1
fi

# Verification de la validité de l'adresse email de l'expéditeur
# Si l'adresse email de l'expéditeur n'est pas spécifiée, on utilise le login SMTP
if [ -z "$SENDER_EMAIL" ]; then
    SENDER_EMAIL=$(echo "$SMTP_LOGIN" | sed 's/%40/@/g')
fi

# Fonction d'envoi d'un mail pour notifier l'ajout d'un utilisateur
send_mail() {
    USER_NAME="$1"
    USER_SURNAME="$2"
    USER_USERNAME="$3"
    USER_PASSWORD="$4"
    USER_EMAIL="$5"
    SENDER_EMAIL="$6"
    SMTP_LOGIN="$7"
    SMTP_PASSWORD="$8"
    SMTP_SERVER="$9"
    SERVER_IP="${10}"

    # Création du message
    message="Bonjour $USER_NAME $USER_SURNAME,

Votre compte a été créé sur le serveur $SERVER_IP.

Voici les informations de connexion :
Nom d'utilisateur : $USER_USERNAME
Mot de passe : $USER_PASSWORD

Le mot de passe doit être changé lors de la première connexion."

    # Envoi du mail
    mail --subject "Création de compte" \
        --exec "set sendmail=smtp://$SMTP_LOGIN:$SMTP_PASSWORD@$SMTP_SERVER" \
        --append "From:$SENDER_EMAIL" \
        "$USER_EMAIL" <<<"$message" &>/dev/null
}

# Fonction pour ajouter une tache cron
add_cron() {
    crontab -l 2>/dev/null | {
        cat
        echo "$1"
    } | crontab -
}

# Fonction de démarrage du service cron
start_cron() {
    # Condition pour vérifier si le système utilise systemd ou init
    if [ -n "$(pidof systemd)" ]; then
        systemctl enable cron
        systemctl start cron
    else
        service cron start
    fi
}

# Fonction d'installation de Eclipse IDE for Java Developers
eclipse_install() {
    # Installation de curl si nécessaire
    apt install -y curl

    # Récupération de la dernière version d'Eclipse IDE for Java Developers
    # depuis le site officiel pour Linux 64-bit
    curl https://www.eclipse.org/downloads/packages/ -o /tmp/eclipse.html
    eclipse_url=$(grep -oP "/technology/epp/downloads/release/[^/]+/R/eclipse-java-[^/]+-R-linux-gtk-x86_64.tar.gz" /tmp/eclipse.html | head -n 1)
    eclipse_url="https://www.eclipse.org/downloads/download.php?file=$eclipse_url&r=1"

    # Téléchargement de l'archive
    curl -L "$eclipse_url" -o /tmp/eclipse.tar.gz

    # Extraction de l'archive dans /usr/local/share
    tar -xzf /tmp/eclipse.tar.gz -C /usr/local/share

    # Changement du propriétaire du répertoire
    chown -R root:root /usr/local/share/eclipse

    # Création d'un lien symbolique vers le binaire
    ln -s /usr/local/share/eclipse/eclipse /usr/local/bin/eclipse

    # Nettoyage des fichiers temporaires
    rm /tmp/eclipse.html
    rm /tmp/eclipse.tar.gz
}

# Fonction de configuration du pare-feu
firewall_setup() {
    # Installation de ufw si nécessaire
    apt install ufw -y

    # Activation du pare-feu
    ufw enable

    # Blocage des connexions de type FTP
    ufw deny ftp

    # Blocage des connexions dans le protocole UDP
    ufw deny proto udp from any to any
}

# Fonction d'installation de Nextcloud
nextcloud_install() {
    # Installation de snapd si nécessaire sur la machine distante
    apt install snapd -y

    # Installation de Nextcloud sur la machine distante
    snap install nextcloud

    # Configuration de l'administrateur Nextcloud
    /snap/bin/nextcloud.manual-install "nextcloud-admin" "N3x+_Cl0uD"
}

# Fonction d'ajout d'un utilisateur à Nextcloud
nextcloud_add_user() {
    USER_NAME="$1"
    USER_SURNAME="$2"
    USER_USERNAME="$3"
    USER_PASSWORD="$4"

    # Ajout de l'utilisateur à Nextcloud sur la machine distante
    OC_PASS="$USER_PASSWORD" /snap/bin/nextcloud.occ user:add \
        --password-from-env \
        --display-name "$USER_NAME $USER_SURNAME" \
        "$USER_USERNAME"
}

# Fonction de configuration et d'installation du monitoring
monitoring_install() {
    # Installation des dépendances pour le monitoring
    apt install -y snapd jq curl

    # Installation de Node Exporter
    snap install node-exporter --edge

    # Activation des permissions pour Node Exporter
    snap connect node-exporter:hardware-observe
    snap connect node-exporter:mount-observe
    snap connect node-exporter:network-observe
    snap connect node-exporter:system-observe

    # Ajout des collectors systemd et processes à Node Exporter
    snap set node-exporter collectors="systemd processes"

    # Installation de Prometheus
    snap install prometheus

    # Attente de la disponibilité de l'API de Prometheus
    while [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090)" = "000" ]; do :; done

    # Ajout de la configuration de Node Exporter à Prometheus
    cat <<EOF >>/var/snap/prometheus/current/prometheus.yml
  - job_name: node
    static_configs:
      - targets: ['localhost:9100']
EOF

    # Redémarrage de Prometheus
    snap restart prometheus

    # Installation de Grafana
    snap install grafana --channel=rock/edge

    # Attente de la disponibilité de l'API de Grafana
    while [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)" = "000" ]; do :; done

    GRAFANA_URL="http://admin:admin@localhost:3000"

    DATASOURCE_NAME="Prometheus"
    DATASOURCE_TYPE="prometheus"
    DATASOURCE_URL="http://localhost:9090"

    # Création de la source de données Prometheus sur Grafana
    curl -s -X POST -H "Content-Type:application/json" -d "{\
            \"name\":\"$DATASOURCE_NAME\",\
            \"type\":\"$DATASOURCE_TYPE\",\
            \"url\":\"$DATASOURCE_URL\",\
            \"access\":\"proxy\",\
            \"basicAuth\":false\
        }" \
        "$GRAFANA_URL/api/datasources"

    # Récupération de l'ID et de l'UID de la source de données Prometheus sur Grafana
    DATASOURCE_ID=$(curl -s -X GET "$GRAFANA_URL/api/datasources/id/$DATASOURCE_NAME" | jq '.id')
    DATASOURCE_UID=$(curl -s -X GET "$GRAFANA_URL/api/datasources/$DATASOURCE_ID" | jq '.uid' | tr -d '"')

    INPUT_NAME="DS_PROMETHEUS"
    INPUT_TYPE="datasource"
    INPUT_PLUGIN_ID="prometheus"
    INPUT_VALUE="$DATASOURCE_UID"

    # ID du dashboard "Node Exporter Full"
    DASHBOARD_ID=1860

    # Création du fichier JSON de configuration du dashboard
    dashboard_json=$(curl -s -X GET "$GRAFANA_URL/api/gnet/dashboards/$DASHBOARD_ID" | jq '.json')
    echo "{\
        \"dashboard\":$dashboard_json,\
        \"overwrite\":true,\
        \"inputs\":[{\
            \"name\":\"$INPUT_NAME\",\
            \"type\":\"$INPUT_TYPE\",\
            \"pluginId\":\"$INPUT_PLUGIN_ID\",\
            \"value\":\"$INPUT_VALUE\"}]\
        }" >/tmp/dashboard.json

    # Importation du dashboard sur Grafana
    curl -s -X POST -H "Content-Type: application/json" -d @/tmp/dashboard.json "$GRAFANA_URL/api/dashboards/import"

    # Nettoyage des fichiers temporaires
    rm /tmp/dashboard.json
}

# Activation du service cron
start_cron

# Récupération du chemin du script
script_path=$(dirname "$(realpath "$0")")

# Création d'une clé SSH pour l'utilisateur root pour les taches cron
ssh-keygen -t ed25519 -f /root/.ssh/id_cron -q -N ""
ssh-copy-id -i /root/.ssh/id_cron.pub "$SERVER_USER@$SERVER_IP"

# Création du répertoire "shared" dans le répertoire /home appartenant à root
# avec tous les droits pour tout le monde
mkdir /home/shared
chown root:root /home/shared
chmod 755 /home/shared # Permissions par défaut

# Création du répertoire "saves" sur la machine distante
ssh "$SERVER_USER@$SERVER_IP" mkdir "$SAVES_DIR"
ssh "$SERVER_USER@$SERVER_IP" chown "$SERVER_USER:$SERVER_USER" "$SAVES_DIR"
ssh "$SERVER_USER@$SERVER_IP" chmod 777 "$SAVES_DIR"

# Tout les jours de la semaine hors week-end à 23h, on compressera le
# répertoire "a_sauver" de chaque utilisateur et on le copiera sur la machine
# distante dans le répertoire "saves". Le fichier sera nommé
# "save-<utilisateur>.tgz" et doit écraser le fichier précédent s'il existe.
add_cron "0 23 * * 1-5 \
    for h in /home/*; do \
        USERNAME=\$(basename \"\$h\"); \
        if [ -d \"/home/\$USERNAME/a_sauver\" ]; then \
            tar -czf \"/tmp/save_\$USERNAME.tgz\" --directory=\"/home/\$USERNAME/a_sauver\" .; \
        fi; \
    done; \
    scp -i /root/.ssh/id_cron -p /tmp/save_*.tgz \"$SERVER_USER@$SERVER_IP:$SAVES_DIR/\"; \
    rm /tmp/save_*.tgz"

# Création du script de restauration de sauvegarde
cat <<EOF >/home/retablir_sauvegarde
#!/bin/sh

# Récupération de l'utilisateur courant
username=\$(whoami)

# Récupération de la sauvegarde du répertoire "a_sauver" de l'utilisateur
scp -p $SERVER_USER@$SERVER_IP:$SAVES_DIR/save-\$username.tgz /home/\$username/save-\$username.tgz 2> /dev/null

# Si la sauvegarde n'existe pas, on arrête le script
if [ ! -f /home/\$username/save-\$username.tgz ]; then
    echo "Aucune sauvegarde n'a été trouvée"
    exit 1
fi

# Suppression du contenu du répertoire "a_sauver" de l'utilisateur
rm -rf /home/\$username/a_sauver/*

# Extraction de la sauvegarde dans le répertoire "a_sauver" de l'utilisateur
tar -xzf /home/\$username/save-\$username.tgz --directory=/home/\$username/a_sauver .

# Suppression de la sauvegarde
rm /home/\$username/save-\$username.tgz
EOF
chown root:root /home/retablir_sauvegarde
chmod 755 /home/retablir_sauvegarde

# Installation de Eclipse IDE for Java Developers
eclipse_install

# Configuration du pare-feu
firewall_setup

# Installation de Nextcloud sur le serveur distant
ssh "$SERVER_USER@$SERVER_IP" "$(declare -f nextcloud_install); nextcloud_install"

# Création du script de tunnel SSH
cat <<EOF >/home/tunnel_ssh
#!/bin/sh

# Création du tunnel SSH
ssh -L 4242:$SERVER_IP:80 -NT $SERVER_USER@$SERVER_IP
EOF
chown root:root /home/tunnel_ssh
chmod 755 /home/tunnel_ssh

# Installation du monitoring Prometheus et Grafana sur le serveur distant
ssh "$SERVER_USER@$SERVER_IP" "$(declare -f monitoring_install); monitoring_install"

# Création du script de tunnel SSH pour l'accès à Grafana
cat <<EOF >/root/tunnel_grafana
#!/bin/sh

# Création du tunnel SSH
ssh -L 3000:$SERVER_IP:3000 -NT $SERVER_USER@$SERVER_IP
EOF
chown root:root /root/tunnel_grafana
chmod 755 /root/tunnel_grafana

# Lecture du fichier accounts.csv ligne par ligne et création des utilisateurs
while IFS=';' read -r name surname mail password; do
    # On ignore la première ligne du fichier contenant les noms des colonnes
    if [ "$name" = "Name" ]; then
        continue
    fi

    # Création du nom d'utilisateur en minuscule et en remplaçant les espaces par des tirets
    username=$(echo "$(echo "$name" | cut -c 1)$surname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # Affichage du nom d'utilisateur pour indiquer le début de la création de l'utilisateur
    echo "Creating user $username"

    # Création de l'utilisateur
    adduser --home "/home/$username" \
        --shell /bin/bash \
        --disabled-password \
        --gecos "$name $surname" \
        --quiet \
        "$username"

    # Modification du mot de passe de l'utilisateur
    echo "$username:$password" | chpasswd

    # Expiration du mot de passe de l'utilisateur
    # pour forcer la modification du mot de passe à la première connexion
    passwd --quiet --expire "$username"

    # Création d'une clé SSH pour l'utilisateur
    mkdir "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    ssh-keygen -t ed25519 -f "/home/$username/.ssh/id_ed25519" -q -N "" -C "$username@$(hostname)"
    chown -R "$username:$username" "/home/$username/.ssh"

    # Ajout de la clé publique de l'utilisateur dans le fichier authorized_keys distant
    ssh-copy-id -i "/home/$username/.ssh/id_ed25519.pub" $SERVER_USER@$SERVER_IP

    # Création du répertoire "a_sauver" dans le répertoire personnel de l'utilisateur
    mkdir "/home/$username/a_sauver"
    chown "$username:$username" "/home/$username/a_sauver"
    chmod 755 "/home/$username/a_sauver" # Permissions par défaut

    # Envoi d'un mail à l'adresse du destinataire avec les informations de
    # connexion de l'utilisateur nouvellement créé
    ssh -n "$SERVER_USER@$SERVER_IP" "$(declare -f send_mail); send_mail \
        \"$name\" \"$surname\" \"$username\" \"$password\" \"$mail\" \
        \"$SENDER_EMAIL\" \"$SMTP_LOGIN\" \"$SMTP_PASSWORD\" \"$SMTP_SERVER\" \"$SERVER_IP\""

    # Ajout de l'utilisateur à Nextcloud sur le serveur distant
    ssh -n "$SERVER_USER@$SERVER_IP" "$(declare -f nextcloud_add_user); nextcloud_add_user \
        \"$name\" \"$surname\" \"$username\" \"$password\""

done <"$script_path/accounts.csv"
