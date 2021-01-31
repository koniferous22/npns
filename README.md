# npns
Top-level repository

## Steps to run

1. clone the repository with submodules with `git clone --recursive <<REPO_URL>>` to get all necessary code
  * In case you process gets interrupted you can probably fix it somehow with `git submodule` commands, although I'd suggest removing files and starting again
2. `cd npns`, make sure you're in top-level directory for steps 3-4
3. Create `.env` file with sample config
```
TAG_GATEWAY_ALPINE=lts-alpine3.12
TAG_POSTGRES=latest

ACCOUNT_POSTGRES_USER=npns_user
ACCOUNT_POSTGRES_PASSWORD=secret_password
ACCOUNT_POSTGRES_PORT=5432
ACCOUNT_POSTGRES_DATABASE=account
```
4. `docker-compose up`
5. Have fun

**TODO**
* fix docker tags