#!/bin/bash
set -euo pipefail

cloned_dir=`dirname $0`
echo "Location of setup script: \"$cloned_dir\""
echo "Setting up directories for docker volumes"
mkdir -p "$cloned_dir/.docker/account_challenge_db"
mkdir -p "$cloned_dir/.docker/content_db"
mkdir -p "$cloned_dir/.docker/pgadmin"
mkdir -p "$cloned_dir/.docker/postgres-scripts"
echo "Setting permission '777, (all write)' for created pgadmin directory bc of docker errors"
chmod 777 "$cloned_dir/.docker/pgadmin"

echo "Initializing .env file"
echo "# TODO when editing this file, please update
# * README.md
# * setup.sh

NODE_ENV=development

IMAGE_TAG_GATEWAY_ALPINE=current-alpine3.12
IMAGE_TAG_MULTI_WRITE_PROXY_ALPINE=current-alpine3.12
IMAGE_TAG_ACCOUNT_SERVICE_ALPINE=current-alpine3.12
IMAGE_TAG_CHALLENGE_SERVICE_ALPINE=current-alpine3.12
IMAGE_TAG_POSTGRES=latest
IMAGE_TAG_MARIADB=latest
IMAGE_TAG_MONGO=latest
IMAGE_TAG_PGADMIN=latest
IMAGE_TAG_REDIS=rc-buster

GATEWAY_CONTAINER_NAME=npns_gateway
GATEWAY_PORT=4000
GATEWAY_GRAPHQL_PATH=/graphql

MULTI_WRITE_PROXY_CONTAINER_NAME=npns_multi_write_proxy
MULTI_WRITE_PROXY_PORT=4001
MULTI_WRITE_PROXY_GRAPHQL_PATH=/graphql
MULTI_WRITE_PROXY_HMAC_SECRET=mwp_secret
MULTI_WRITE_PROXY_HMAC_ALGORITHM=sha256

ACCOUNT_SERVICE_CONTAINER_NAME=npns_account_service
ACCOUNT_SERVICE_PORT=4002
ACCOUNT_SERVICE_GRAPHQL_PATH=/graphql
ACCOUNT_SERVICE_JWT_SECRET=some_jwt_secret
ACCOUNT_SERVICE_JWT_ALGORITHM=HS256
# Testing SMTP mailbox https://ethereal.email/
ACCOUNT_SERVICE_NODEMAILER_HOST=smtp.ethereal.email
ACCOUNT_SERVICE_NODEMAILER_PORT=587
ACCOUNT_SERVICE_NODEMAILER_USER=oren.cremin@ethereal.email
ACCOUNT_SERVICE_NODEMAILER_PASSWORD=86GXzmB8sDN2u2Ycuy
ACCOUNT_SERVICE_NOTIFICATION_SENDER_EMAIL=noreply@npns.biz

CHALLENGE_SERVICE_CONTAINER_NAME=npns_challenge_service
CHALLENGE_SERVICE_PORT=4003
CHALLENGE_SERVICE_GRAPHQL_PATH=/graphql
CHALLENGE_SERVICE_GRID_FS_MAX_FILES=10
CHALLENGE_SERVICE_GRID_FS_MAX_FILE_SIZE=10000000
CHALLENGE_SERVICE_LIMIT_CONTENT_UPLOADS=10
CHALLENGE_SERVICE_LIMIT_EDIT_COUNT=3

ACCOUNT_POSTGRES_ROOT_USER=root
ACCOUNT_POSTGRES_ROOT_PASSWORD=postgres_root_password
ACCOUNT_POSTGRES_USER=account
ACCOUNT_POSTGRES_PASSWORD=secret_password
ACCOUNT_POSTGRES_PORT=5432
ACCOUNT_POSTGRES_DATABASE=account

# NOTE for now should be identical with account setup
CHALLENGE_POSTGRES_USER=challenge
CHALLENGE_POSTGRES_PASSWORD=secret_password
CHALLENGE_POSTGRES_PORT=5432
CHALLENGE_POSTGRES_DATABASE=challenge

CONTENT_MONGODB_ROOT_USER=root
CONTENT_MONGODB_ROOT_PASSWORD=mongo_root_password
CONTENT_MONGODB_USER=npns_user
CONTENT_MONGODB_PASSWORD=secret_password
CONTENT_MONGODB_DATABASE=content
CONTENT_MONGODB_PORT=27017

VERIFICATION_TOKEN_CACHE_PORT=6379
VERIFICATION_TOKEN_CACHE_PASSWORD=secret_redis_password
VERIFICATION_TOKEN_EXPIRATION_TIME=43200

CHALLENGE_VIEW_CACHE_PORT=6380
CHALLENGE_VIEW_CACHE_PASSWORD=secret_redis_password2
CHALLENGE_VIEW_EXPIRATION_TIME=900

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

echo "Installing all dependencies"
"$cloned_dir/npm-all.sh" install gateway multi-write-proxy services/account services/challenge

echo "Setup finished"
echo "run \`docker-compose up\` to start the app"
