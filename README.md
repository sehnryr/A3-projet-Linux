# Projet Linux

## Sommaire
- [Projet Linux](#projet-linux)
  - [Sommaire](#sommaire)
  - [Cahier des charges](#cahier-des-charges)
  - [Utilisation](#utilisation)
  - [Nextcloud](#nextcloud)
  - [Monitoring](#monitoring)
  - [Docker](#docker)

## Cahier des charges

- [x] Création d'utilisateurs depuis un fichier CSV
- [x] Envoi d'un mail lors de la création d'un utilisateur
- [x] Sauvegarde automatique des dossiers "a_sauver" des utilisateurs sur un
  serveur distant
- [x] Création d'un script de restauration des dossiers "a_sauver" des
  utilisateurs
- [x] Installation de Eclipse pour les utilisateurs
- [x] Régler le pare-feu
- [x] Installer Nextcloud sur le serveur distant
- [x] Connection ssh pour les utilisateurs
- [x] Ajouter un outil de monitoring sur le serveur distant de Nextcloud

## Utilisation

Pour lancer le projet, il faut exécuter le script `main.sh` en tant que
super-utilisateur :
```
$ su root
# ./main.sh <url du serveur smtp> <login du serveur smtp> <mot de passe du serveur smtp>
```

## Nextcloud

Pour acceder à Nextcloud, il faut tunneliser le port 80 du serveur distant
vers le port 4242 sur la machine locale :
```
$ /home/tunnel_ssh
```

Ou alors, utiliser la commande ssh suivante :
```
$ ssh -L 4242:<ip>:80 <user>@<ip>
```

## Monitoring

Pour accéder à l'outil de monitoring, il faut tunneliser le port 3000 du serveur
distant vers le port 3000 sur la machine locale :
```
# /root/tunnel_grafana
```

Ou alors, utiliser la commande ssh suivante :
```
# ssh -L 3000:<ip>:3000 <user>@<ip>
```

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

Ici, le conteneur est lancé en mode interactif, ce qui permet de pouvoir
interagir avec le conteneur. Il est aussi lancé en mode rm qui permet de
supprimer le conteneur une fois qu'il est arrêté.

Le volume `$(pwd):/coding:z` permet de partager le répertoire courant avec le
conteneur. Le volume `$SSH_AUTH_SOCK:/ssh-agent:z` permet de partager le
socket SSH avec le conteneur et l'environnement `SSH_AUTH_SOCK=/ssh-agent`
permet de faire pointer le socket SSH vers le socket partagé.
