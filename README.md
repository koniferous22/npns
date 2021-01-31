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
4. `docker-compose up`
5. Have fun

**TODO**
* fix docker tags