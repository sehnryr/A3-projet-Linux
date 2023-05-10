# Projet Linux

## Cahier des charges

- [x] Création d'utilisateurs depuis un fichier CSV
- [x] Envoi d'un mail lors de la création d'un utilisateur
- [x] Sauvegarde automatique des dossiers "a_sauver" des utilisateurs sur un
  serveur distant
- [x] Création d'un script de restauration des dossiers "a_sauver" des
  utilisateurs
- [ ] Installation de Eclipse pour les utilisateurs
- [x] Régler le pare-feu
- [ ] Installer Nextcloud sur le serveur distant
- [ ] Ajouter un outil de monitoring sur le serveur distant de Nextcloud

## Docker

Pour lancer le projet dans un conteneur Docker, il faut d'abord construire 
l'image Docker avec la commande suivante :
```sh
docker image build -t a3-projet-linux-image .
```

Ensuite, pour lancer le conteneur, il faut exécuter la commande suivante :
```sh
docker container run \
    --interactive \
    --tty \
    --rm \
    --volume $(pwd):/coding:z \
    --volume $SSH_AUTH_SOCK:/ssh-agent:z \
    --env SSH_AUTH_SOCK=/ssh-agent \
    --privileged \
    a3-projet-linux-image
```

Il est nécessaire de démarrer le service `cron` dans le conteneur pour que
les tâches planifiées soient exécutées. Pour cela, il faut exécuter la
commande suivante dans le conteneur :
```sh
service cron start
```

Il est également requis de démarrer le service `ufw` dans le conteneur pour
que le pare-feu soit activé. Pour cela, il faut exécuter la commande suivante
dans le conteneur :
```sh
ufw enable
```

Ici, le conteneur est lancé en mode interactif, ce qui permet de pouvoir
interagir avec le conteneur. Il est aussi lancé en mode rm qui permet de
supprimer le conteneur une fois qu'il est arrêté.

Le volume `$(pwd):/coding:z` permet de partager le répertoire courant avec le
conteneur. Le volume `$SSH_AUTH_SOCK:/ssh-agent:z` permet de partager le
socket SSH avec le conteneur et l'environnement `SSH_AUTH_SOCK=/ssh-agent`
permet de faire pointer le socket SSH vers le socket partagé.
