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

GATEWAY_CONTAINER_NAME=npns_gateway
GATEWAY_PORT=4000

ACCOUNT_POSTGRES_USER=npns_user
ACCOUNT_POSTGRES_PASSWORD=secret_password
ACCOUNT_POSTGRES_PORT=5432
# not needed
#ACCOUNT_POSTGRES_HOST=0.0.0.0
ACCOUNT_POSTGRES_DATABASE=account

TAG_MARIADB_ROOT_PWD=mariadb_root_pwd
TAG_MARIADB_DATABASE=tag
TAG_MARIADB_USER=npns_user
TAG_MARIADB_PASSWORD=secret_password
TAG_MARIADB_PORT=3306
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
echo "Executing migrations"
yesno yesno_result "Do you need root permissions to connect to container"
exec_in_docker_opts=
if [ $yesno_result ]; then
    exec_in_docker_opts="--root"
fi

$cloned_dir/exec-in-container.sh npns_gateway $exec_in_docker_opts -- npm run orm -- migration:run -c account
$cloned_dir/exec-in-container.sh npns_gateway $exec_in_docker_opts -- npm run orm -- migration:run -c tag

echo "Setup complete"
