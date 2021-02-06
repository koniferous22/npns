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
create_db_collection_js="db.getMongo().getDB(\"$CHALLENGE_MONGODB_DATABASE\").createCollection(\"$CHALLENGE_MONGODB_DATABASE\")"
create_db_user_js="db.getMongo().getDB(\"$CHALLENGE_MONGODB_DATABASE\").createUser($user_record)"
# Collection needs to be setup, because otherwise database won't be created
echo "Creating collection and mongo user for challenge database"
docker run -it --rm --network "$temp_network"  mongo \
    mongo --host "$temp_name" \
        -u "$CHALLENGE_MONGODB_ROOT_USER" \
        -p "$CHALLENGE_MONGODB_ROOT_PASSWORD" \
        "$CHALLENGE_MONGODB_DATABASE"
#         --eval "$create_db_collection_js;$create_db_user_js"
# NOTE: all of this is required in order to run mongod in --auth mode, it assumes that user and database already exist

echo "Stopping temporary container"
docker stop "$temp_name"

echo "Removing temporary network"
docker network rm "$temp_network"

echo "Running docker-compose for executing migrations"
docker-compose up -d

echo "Executing migrations"
cd $cloned_dir
docker-compose exec gateway npm run orm -- migration:run -c account
docker-compose exec gateway npm run orm -- migration:run -c tag
# docker-compose exec gateway npm run orm -- migration:run -c challenge 

# CLEANUP
docker-compose down
echo "Docker setup complete"
