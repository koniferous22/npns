#!/bin/bash
set -euo pipefail

cloned_dir=`dirname $0`
echo "Location of setup script: \"$cloned_dir\""
echo "Setting up directories for docker volumes"
mkdir -p "$cloned_dir/.docker/account_tag_db"
mkdir -p "$cloned_dir/.docker/challenge_db"
mkdir -p "$cloned_dir/.docker/pgadmin"
mkdir -p "$cloned_dir/.docker/postgres-scripts"
echo "Setting permission '777, (all write)' for created pgadmin directory bc of docker errors"
chmod 777 "$cloned_dir/.docker/pgadmin"

echo "Initializing .env file"
echo "# TODO when editing this file, please update
# * README.md
# * setup.sh

IMAGE_TAG_GATEWAY_ALPINE=lts-alpine3.12
IMAGE_TAG_POSTGRES=latest
IMAGE_TAG_MARIADB=latest
IMAGE_TAG_MONGO=latest
IMAGE_TAG_PGADMIN=latest

GATEWAY_CONTAINER_NAME=npns_gateway
GATEWAY_PORT=4000

ACCOUNT_POSTGRES_ROOT_USER=root
ACCOUNT_POSTGRES_ROOT_PASSWORD=postgres_root_password
ACCOUNT_POSTGRES_USER=account
ACCOUNT_POSTGRES_PASSWORD=secret_password
ACCOUNT_POSTGRES_PORT=5432
ACCOUNT_POSTGRES_DATABASE=account

# FOR now not needed, because tag database will share same instance as account database
# Will be separated in the future
# TAG_MARIADB_USER=npns_user
# TAG_MARIADB_PASSWORD=secret_password
# TAG_MARIADB_ROOT_PWD=mariadb_root_pwd
# TAG_MARIADB_DATABASE=tag
# TAG_MARIADB_PORT=3306

# NOTE for now should be identical with account setup
TAG_POSTGRES_USER=tag
TAG_POSTGRES_PASSWORD=secret_password
TAG_POSTGRES_PORT=5432
TAG_POSTGRES_DATABASE=tag

CHALLENGE_MONGODB_ROOT_USER=root
CHALLENGE_MONGODB_ROOT_PASSWORD=mongo_root_password
CHALLENGE_MONGODB_USER=npns_user
CHALLENGE_MONGODB_PASSWORD=secret_password
CHALLENGE_MONGODB_DATABASE=challenge
CHALLENGE_MONGODB_PORT=27017

PGADMIN_EMAIL=admin@postgres.com
PGADMIN_PASSWORD=password
PGADMIN_PORT=8080
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
yesno yesno_result "Do you need root permissions to work with docker"
if [ $yesno_result ]; then
    sudo "$cloned_dir/docker_setup.sh"
else
    "$cloned_dir/docker_setup.sh"
fi

echo "Setup finished"