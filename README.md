# npns
Top-level repository

## Requirements
* npm
* node
* docker (+ configure `docker` group for distributions such as fedora)

## Steps to run

1. clone the repository with submodules with `git clone --recursive <<REPO_URL>>` to get all necessary code
  * In case you process gets interrupted you can probably fix it somehow with `git submodule` commands, although I'd suggest removing files and starting again
2. `cd npns`
3. Run `./setup.sh`, this command does following steps
  * Creates directory .docker (ignored by `.gitignore` where volumes will be stored)
    * **(WORKAROUND)** For pgadmin adds permission to all users, because of some docker issues
  * Initialized `.env` file with following contents
  ```
  # TODO when editing this file, please update
  # * README.md
  # * setup.sh

  NODE_ENV=development

  IMAGE_TAG_GATEWAY_ALPINE=current-alpine3.12
  IMAGE_TAG_TAG_SERVICE_ALPINE=current-alpine3.12
  IMAGE_TAG_ACCOUNT_SERVICE_ALPINE=current-alpine3.12
  IMAGE_TAG_POSTGRES=latest
  IMAGE_TAG_MARIADB=latest
  IMAGE_TAG_MONGO=latest
  IMAGE_TAG_PGADMIN=latest
  IMAGE_TAG_REDIS=rc-buster

  GATEWAY_CONTAINER_NAME=npns_gateway
  GATEWAY_PORT=4000

  TAG_SERVICE_CONTAINER_NAME=npns_tag_service
  TAG_SERVICE_PORT=4001

  ACCOUNT_SERVICE_CONTAINER_NAME=npns_account_service
  ACCOUNT_SERVICE_PORT=4002

  CHALLENGE_SERVICE_CONTAINER_NAME=npns_challenge_service
  CHALLENGE_SERVICE_PORT=4003

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

  VERIFICATION_TOKEN_CACHE_PORT=6379
  VERIFICATION_TOKEN_CACHE_PASSWORD=secret_redis_password

  PGADMIN_EMAIL=admin@postgres.com
  PGADMIN_PASSWORD=password
  PGADMIN_PORT=8080
  ```
  * Asks for option whether you need root permissions to run docker (in most cases not necessary)
    * For some linux system (edge cases) it should be possible to configure system group
  * Sets up mongodb user and collection, by executing mongo shell and evaluating javascript
    * `mongo -u $CHALLENGE_MONGODB_ROOT_USER -p $CHALLENGE_MONGODB_ROOT_PASSWORD $CHALLENGE_MONGODB_DATABASE --eval "<JAVASCRIPT_CODE>"`
  * Populates databases on shared volume with migrations located in
    * `gateway/src/account-service/migrations/`
    * `gateway/src/tag-service/migrations/`
  * Essentially runs following commands
  ```
  docker-compose exec gateway npm run orm -- migration:run -c account
  docker-compose exec gateway npm run orm -- migration:run -c tag
  ```
4. Run the stack with `docker-compose up`
5. Have fun

**TODO**
* docker compose with sharded mongo infrastructure (for example: https://dzone.com/articles/composing-a-sharded-mongodb-on-docker)
* Reconfigure connection for production use
  * Make sure that db connections from gateway/services don't have root permissions
* Split account and tag into two separate db instances due to data security
* Extract db initialization scripts from `docker_setup.sh` into separate scripts
* Reusability improvements
  * Base Docker Image for services
  * Reusable config validation solution
* E2E tests for graphql queries and mutations
* Mocks to be able to develop modules individually and not work in huge monorepo
* DB Future TODO:
  * Define which dbs should have replicas
    * What permissions are required to run migrations (potential refactor)
    * NOTE: postgres issue encountered during development: mikro-orm automatically required replica permission for connection, which was unsafe for application use
  * refactor into micro-orm where possible
* Create production build
  * Docker swarm mode
  * Disable playground on production build
