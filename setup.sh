#!/bin/bash
set -euo pipefail

cloned_dir=`dirname $0`
echo "Location of setup script: \"$cloned_dir\""
echo "Setting up directories for docker volumes"
mkdir -p "$cloned_dir/.docker/account_db"
mkdir -p "$cloned_dir/.docker/tag_db"

echo "Initializing .env file"
echo "# TODO when editing this file, please update
# * README.md
# * setup.sh

IMAGE_TAG_GATEWAY_ALPINE=lts-alpine3.12
IMAGE_TAG_POSTGRES=latest
IMAGE_TAG_MARIADB=latest
IMAGE_TAG_MONGO=latest

GATEWAY_CONTAINER_NAME=npns_gateway
GATEWAY_PORT=4000

ACCOUNT_POSTGRES_USER=npns_user
ACCOUNT_POSTGRES_PASSWORD=secret_password
ACCOUNT_POSTGRES_PORT=5432
ACCOUNT_POSTGRES_DATABASE=account

TAG_MARIADB_USER=npns_user
TAG_MARIADB_PASSWORD=secret_password
TAG_MARIADB_ROOT_PWD=mariadb_root_pwd
TAG_MARIADB_DATABASE=tag
TAG_MARIADB_PORT=3306

CHALLENGE_MONGODB_ROOT_USER=root
CHALLENGE_MONGODB_ROOT_PASSWORD=mongo_root_password
CHALLENGE_MONGODB_USER=npns_user
CHALLENGE_MONGODB_PASSWORD=secret_password
CHALLENGE_MONGODB_DATABASE=challenge
CHALLENGE_MONGODB_PORT=27017
" > "$cloned_dir/.env"

function yesno() {
    local __resultvar=$1
    local input=
    while true
    do
        read -r -p "$2? [Y/n] " input
        case $input in
        [yY][eE][sS]|[yY])
            echo "Yes"
            eval $__resultvar=$input
            break
        ;;
        [nN][oO]|[nN])
            echo "No"
            break
        ;;
        *)
            echo "Invalid input..."
            ;;
        esac
    done
}

yesno_result=
yesno yesno_result "Do you need root permissions to connect to container"
exec_in_docker_opts=
if [ $yesno_result ]; then
    exec_in_docker_opts="--privileged"
fi

echo "Loading generated configuration"
source "$cloned_dir/.env"

# TODO add missing condition sth like 'if (is_mongo_used)' when required
user_record="{user:\"$CHALLENGE_MONGODB_USER\",pwd:\"$CHALLENGE_MONGODB_PASSWORD\",roles:[{role:\"readWrite\",db:\"$CHALLENGE_MONGODB_DATABASE\"}]}"
create_db_collection_js="db.getMongo().getDB(\"$CHALLENGE_MONGODB_DATABASE\").createCollection(\"$CHALLENGE_MONGODB_DATABASE\")"
create_db_user_js="db.getMongo().getDB(\"$CHALLENGE_MONGODB_DATABASE\").createUser($user_record)"
echo "Creating mongo user for challenge database"
docker-compose exec @exec_in_docker_opts challenge_db mongo -u $CHALLENGE_MONGODB_ROOT_USER -p $CHALLENGE_MONGODB_ROOT_PASSWORD $CHALLENGE_MONGODB_DATABASE --eval "$create_db_collection_js;$create_db_user_js"

echo "Executing migrations"
cd $cloned_dir
docker-compose exec $exec_in_docker_opts gateway npm run orm -- migration:run -c account
docker-compose exec $exec_in_docker_opts gateway npm run orm -- migration:run -c tag
docker-compose exec $exec_in_docker_opts gateway npm run orm -- migration:run -c challenge 

echo "Setup complete"
