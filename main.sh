#!/bin/sh

SERVER_USER="ymeloi25"
SERVER_IP="10.30.48.100"
EMAIL="youn@melois.dev"

# Récupération du chemin du script
script_path=$(dirname "$(realpath "$0")")

# Création du répertoire "shared" dans le répertoire /home appartenant à root
# avec tous les droits pour tout le monde
mkdir /home/shared
chown root:root /home/shared
chmod 755 /home/shared # Permissions par défaut

# Création du répertoire "saves" sur la machine distante
ssh "$SERVER_USER@$SERVER_IP" mkdir /home/saves 
ssh "$SERVER_USER@$SERVER_IP" chown root:root /home/saves 
ssh "$SERVER_USER@$SERVER_IP" chmod 777 /home/saves

# Création du script de restauration de sauvegarde
cat << EOF > /home/retablir_sauvegarde
#!/bin/sh

# Récupération de l'utilisateur courant
username=\$(whoami)

# Récupération de la sauvegarde du répertoire "a_sauver" de l'utilisateur
scp -p $SERVER_USER@$SERVER_IP:/home/saves/save-\$username.tgz /home/\$username/save-\$username.tgz

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

# Bloquer les connexions de type FTP et toutes les connexions dans le protocole UDP
ufw deny ftp
ufw deny proto udp from any to any

# Installation de Nextcloud sur le serveur distant
ssh "$SERVER_USER@$SERVER_IP" mkdir -p /var/www
ssh "$SERVER_USER@$SERVER_IP" curl -s https://download.nextcloud.com/server/releases/latest.tar.bz2 | tar -xjf - -C /var/www
ssh "$SERVER_USER@$SERVER_IP" chown -R www-data:www-data /var/www/nextcloud
ssh "$SERVER_USER@$SERVER_IP" sudo -u www-data php /var/www/nextcloud/occ maintenance:install \
    --admin-user "nextcloud-admin" \
    --admin-pass "N3x+_Cl0uD"

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
    useradd --create-home --home-dir "/home/$username" --shell /bin/bash "$username"

    # Modification du mot de passe de l'utilisateur
    echo "$username:$password" | chpasswd

    # Expiration du mot de passe de l'utilisateur
    # pour forcer la modification du mot de passe à la première connexion
    passwd --quiet --expire "$username"

    # Création du répertoire "a_sauver" dans le répertoire personnel de l'utilisateur
    mkdir "/home/$username/a_sauver"
    chown "$username:$username" "/home/$username/a_sauver"
    chmod 755 "/home/$username/a_sauver" # Permissions par défaut

    # TODO: envoyer un mail à EMAIL avec les informations de connexion de l'utilisateur

    # Tout les jours de la semaine hors week-end à 23h, on compressera le 
    # répertoire "a_sauver" de l'utilisateur et on le copiera sur la machine distante
    # dans le répertoire "saves". Le fichier sera nommé "save-<utilisateur>.tgz"
    # et doit écraser le fichier précédent s'il existe.
    crontab -l | {
        cat;
        echo "0 23 * * 1-5 \
        tar -cz --directory=/home/$username/a_sauver . | \
        SSH_AUTH_SOCK=$SSH_AUTH_SOCK ssh $SERVER_USER@$SERVER_IP 'cat > /home/saves/save-$username.tgz'";
    } | crontab - # Ajout de la tâche dans le crontab de l'utilisateur

done < "$script_path/accounts.csv"
