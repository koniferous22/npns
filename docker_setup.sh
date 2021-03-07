#!/bin/bash

cloned_dir=`dirname $0`
# NOTE: abs path needed just bc of some bash errors
abs_path=`realpath $cloned_dir`
cd $cloned_dir

echo "Loading generated configuration"
source "$cloned_dir/.env"

echo "Running temporary container for database user set up"
temp_network=temp_network
temp_name=temp_name
echo "Creating temporary network"
docker network create "$temp_network"
docker run -it -d \
    -v "$abs_path/.docker/challenge_db":"/data/db" \
    --name "$temp_name" \
    --network "$temp_network" \
    --expose "$CHALLENGE_MONGODB_PORT" \
    -e MONGO_INITDB_ROOT_USERNAME="$CHALLENGE_MONGODB_ROOT_USER" \
    -e MONGO_INITDB_ROOT_PASSWORD="$CHALLENGE_MONGODB_ROOT_PASSWORD" \
    -e MONGO_INITDB_DATABASE="$CHALLENGE_MONGODB_DATABASE" \
    mongo \
        mongod --auth

user_record="{user:\"$CHALLENGE_MONGODB_USER\",pwd:\"$CHALLENGE_MONGODB_PASSWORD\",roles:[{role:\"readWrite\",db:\"$CHALLENGE_MONGODB_DATABASE\"}]}"
create_db_collection_js="db.getSiblingDB(\"$CHALLENGE_MONGODB_DATABASE\").createCollection(\"$CHALLENGE_MONGODB_DATABASE\")"
create_db_user_js="db.getSiblingDB(\"$CHALLENGE_MONGODB_DATABASE\").createUser($user_record)"
# Collection needs to be setup, because otherwise database won't be created
echo "Creating collection and mongo user for challenge database"
docker run -it --rm --network "$temp_network" -v "$abs_path/wait-for-it.sh:/utils/wait-for-it.sh" mongo:$IMAGE_TAG_MONGO \
    bash -c "/utils/wait-for-it.sh -h \"$temp_name\" -p \"$CHALLENGE_MONGODB_PORT\" && sleep 10 && 
        mongo --host $temp_name \
            -u $CHALLENGE_MONGODB_ROOT_USER \
            -p $CHALLENGE_MONGODB_ROOT_PASSWORD \
            --eval '$create_db_collection_js;$create_db_user_js'"
# NOTE: all of this is required in order to run mongod in --auth mode, it assumes that user and database already exist

echo "Stopping and removing temporary container"
docker stop "$temp_name"
docker container rm "$temp_name"

temp_name=temp_postgres_name

echo "Generating scripting file for postgres entrypoint"
echo "
CREATE ROLE $ACCOUNT_POSTGRES_USER WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD '$ACCOUNT_POSTGRES_PASSWORD';
CREATE DATABASE $ACCOUNT_POSTGRES_DATABASE;
GRANT ALL PRIVILEGES ON DATABASE $ACCOUNT_POSTGRES_DATABASE TO $ACCOUNT_POSTGRES_USER;
CREATE ROLE $TAG_POSTGRES_USER WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD '$TAG_POSTGRES_PASSWORD';
CREATE DATABASE $TAG_POSTGRES_DATABASE;
GRANT ALL PRIVILEGES ON DATABASE $TAG_POSTGRES_DATABASE TO $TAG_POSTGRES_USER;
" >  "$abs_path/.docker/postgres-scripts/init-postgres.sql"

echo "Removing temporary network"
docker network rm "$temp_network"

echo "Running docker-compose for executing migrations"
echo "[WARNING] In case of bad configuration following command will fail"
docker-compose up -d

echo "Executing migrations"
cd $cloned_dir

docker-compose exec tag_service npm run orm -- migration:run
docker-compose exec account_service npm run orm -- migration:run
#docker-compose exec gateway npm run migrate:mongo up

# CLEANUP
docker-compose down
echo "Docker setup complete"
echo "run \`docker-compose up\` to start the app"
