# Utilisation de l'image debian:latest comme base
FROM debian:latest

# Mise à jour des dépendances
RUN apt-get update 
RUN apt-get install -y ssh
