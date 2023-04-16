#!/bin/sh

SERVER_USER="ymeloi25"
SERVER_IP="10.30.48.100"
EMAIL="youn@melois.dev"

# get the path of the script
script_path=$(dirname "$(realpath "$0")")

# read the file accounts.csv and create the users
while IFS=';' read -r name surname mail password; do
    # skip the first line
    if [ "$name" = "Name" ]; then
        continue
    fi

    # store the username in a variable
    username=$(echo "$name" | tr '[:upper:]' '[:lower:]' | head -c 1)$(echo "$surname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # print the username
    echo "Creating user $username"

    # create the user
    useradd --create-home \
        --home-dir "/home/$username" \
        "$username"

    # set the password for the user
    echo "$username:$password" | chpasswd

    # force the user to change the password at the first login
    passwd --quiet --expire "$username"

    # create the directory "a_sauver" in the home directory of the user
    mkdir "/home/$username/a_sauver"
    chown "$username:$username" "/home/$username/a_sauver"
    chmod 755 "/home/$username/a_sauver" # default permissions

    # TODO: send an email to $EMAIL with the username and the password of the user

done < "$script_path/accounts.csv"

# create the directory "shared" in the /home directory owned by root with all permissions for everyone
mkdir /home/shared
chown root:root /home/shared
chmod 755 /home/shared # default permissions
