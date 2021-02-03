# npns
Top-level repository

## Steps to run

1. clone the repository with submodules with `git clone --recursive <<REPO_URL>>` to get all necessary code
  * In case you process gets interrupted you can probably fix it somehow with `git submodule` commands, although I'd suggest removing files and starting again
2. `cd npns`
3. Run `./setup.sh`, this command does following steps
  * Creates directory .docker (ignored by `.gitignore` where volumes will be stored)
  * Initialized `.env` file with following contents
  ```
  # TODO when editing this file, please update
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
  ```
  * Asks for option whether you need root permissions to run docker (in most cases not necessary)
  * Populates databases on shared volume with migrations located in
    * `gateway/src/account-service/migrations/`
    * `gateway/src/tag-service/migrations/`
  * Essentially runs following commands
  ```
  ./exec-in-container.sh npns_gateway $exec_in_docker_opts -- npm run orm -- migration:run -c account
  ./exec-in-container.sh npns_gateway $exec_in_docker_opts -- npm run orm -- migration:run -c tag
  ```
4. Run the stack with `docker-compose up`
5. Have fun

**TODO**
* pgadmin support in dev `docker-compose`
