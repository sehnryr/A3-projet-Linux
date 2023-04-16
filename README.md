# Projet Linux

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
