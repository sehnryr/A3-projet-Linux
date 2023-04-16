#!/bin/sh

SERVER_USER="ymeloi25"
SERVER_IP="10.30.48.100"
EMAIL="youn@melois.dev"

# Récupération du chemin du script
script_path=$(dirname "$(realpath "$0")")

# Lecture du fichier accounts.csv ligne par ligne et création des utilisateurs
while IFS=';' read -r name surname mail password; do
    # On ignore la première ligne du fichier contenant les noms des colonnes
    if [ "$name" = "Name" ]; then
        continue
    fi

    # Création du nom d'utilisateur en minuscule et en remplaçant les espaces par des tirets
    username=$(echo "$name" | tr '[:upper:]' '[:lower:]' | head -c 1)$(echo "$surname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # Affichage du nom d'utilisateur pour indiquer le début de la création de l'utilisateur
    echo "Creating user $username"

    # Création de l'utilisateur
    useradd --create-home --home-dir "/home/$username" "$username"

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

done < "$script_path/accounts.csv"

# Création du répertoire "shared" dans le répertoire /home appartenant à root
# avec tous les droits pour tout le monde
mkdir /home/shared
chown root:root /home/shared
chmod 755 /home/shared # Permissions par défaut