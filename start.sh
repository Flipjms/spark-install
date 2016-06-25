#!/bin/bash

git submodule add git@github.com:Flipjms/docker-spark.git docker

echo "Enter your spark repository url:"

read SPARK_REPO
git submodule add $SPARK_REPO laravel-spark

#Go to docker folder:
cd docker

TMP_DIR="../.tmp/"

rm -rf "$TMP_DIR"

mkdir $TMP_DIR

#Get running container IDs and save it for later:
docker ps -q >> "${TMP_DIR}running.txt"

#Build and run the containers:
docker-compose up -d nginx mariadb

#Save newly created containers:
docker ps -q | diff --changed-group-format="%>" --unchanged-group-format="" "${TMP_DIR}running.txt" - >> "${TMP_DIR}containers.txt"
#Fetch the workspace container ID
WORKSPACE_ID=$(cat "${TMP_DIR}containers.txt" | grep `docker ps -f ancestor=docker_workspace -q`)

#Fetch the mariadb IP to edit on env file
DB_ID=$(cat "${TMP_DIR}containers.txt" | grep `docker ps -f ancestor=docker_mariadb -q`)
echo $DB_ID
DB_IP=$(docker inspect --format "{{ .NetworkSettings.Networks.docker_default.IPAddress }}" $DB_ID)
docker exec -it ${WORKSPACE_ID} composer install
docker exec -it ${WORKSPACE_ID} npm install

cp ../laravel-spark/.env.example ../laravel-spark/.env

docker exec -it ${WORKSPACE_ID} php artisan key:generate

#Change DB_HOST of env file
cd ../laravel-spark
sed -i -c "s/\(DB_HOST *= *\).*/\1$DB_IP/" .env

cd ../docker
docker exec -it ${WORKSPACE_ID} php artisan migrate
open "http://localhost:8080"
