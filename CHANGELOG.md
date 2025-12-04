# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.17.0] - 2025-12-04

### Changed
- Traefik upgraded to 3.6.2 from 1.7.x

## [0.16.10] - 2025-03-03

### Changed
- Got latest PHP 8.1, 8.2, and 8.3
- Added OPS_CONTAINER_VERSION variable

## [0.16.8] - 2025-01-07

### Added
- Postgres 13 Support
- OPS_EXTRA_SERVICES config
- Apache mod_include for php 7.2+

## [0.16.7] - 2024-07-30

Postgres 9 will be removed in a later version.

### Added
- Postgres 16
- `ops system networking` debug command
- Adminer login plugin

### Changed
- Upgraded Adminer to latest version.


## [0.16.6] - 2024-07-17

This version includes upgrading ops's MariaDB version from 10.3 to 11.4. You
cannot downgrade after upgrading.

### Added
- `ops root`, `ops ssh` commands
- `extra_hosts` option to docker-compose files
- Better support for multi-platform docker image builds through Buddy.works.

### Changed
- Upgrade MariaDB from 10.3 to 11.4. Run `ops system install` and `ops system
refresh-services` to complete the upgrade.
- Fix obsolete notices for docker-compose 'version:' attributes.
- Cleaned up messaging and help text.


## [0.16.5] - 2024-02-27

### Added
- PHP 8.3 support

### Changed
- PHP 8.2 upgraded to 8.2.16 + Debian Bullseye
- PHP 8.1 upgraded to 8.1.28 + Debian Bullseye
- PHP 8.0 upgraded to 8.0.30 + Debian Bullseye
- PHP 7.4 upgraded to 7.4.33 + Debian Bullseye
- PHP 7.3 upgraded to Debian Bullseye
- Node image upgraded to 21-alpine3.19
- Utils image upgraded to alpine:3.19

### Fixed
- PHP 7.2 debian repos now pointing to archive

### Removed
- meta-Ops image. Hacky trick that was never used.

## [0.16.4] - 2024-01-22

### Fixed
- Use complete insert statements when creating database dumps

## [0.16.3] - 2023-01-05

### Fixed
- Docker images for ARM processors

### Added
- PHP 8.2 support

## [0.16.2] - 2022-12-06

### Fixed
- Cert support in WSL
- external.name Warnings

## [0.16.1] - 2022-02-01

### Added
- Nice ops-specific error pages in nginx
- Ability to customize php.ini from ~/.ops/php

### Fixed
- XDebug 3 settings

## [0.16.0] - 2021-12-01

### Changed
- Default backend is now `apache-php80`
- Default available backends now `apache-php74` and `apache-php80`

### Added
- PHP 8.1 support (`apache-php81`)

## [0.15.4] - 2021-11-16

### Changed
- Minio vars changed to MINIO_ROOT_USER and MINIO_ROOT_PASSWORD

## [0.15.3] - 2021-11-03

### Added
- intl extension to 7.3.x and 7.4.x
- alias support

## [0.15.2] - 2021-09-07

### Added
- WebP support in 7.3.x

### Changed
- Upgraded all PHP versions to latest minor version

## [0.15.1] - 2021-02-25

### Added
- PHP 8.0 Support (apache-php80)

### Changed
- PHP 7.3.7 upgraded to 7.3.27
- PHP 7.4.x upgraded to 7.4.15

### Removed
- PHP 7.1.x

## [0.15.0] - 2020-11-18

### Added
- OPS_PHP_XDEBUG config option

### Changed
- XDebug no longer enabled by default in php 7.x images

## [0.14.0] - 2020-04-16

### Added
- OPS_DOMAIN_ALIASES config option

## [0.13.1] - 2020-02-03

### Fixed
- PHP container warnings on dashboard.

## [0.13.0] - 2020-01-09

### Added
- Added PHP 7.4 backend
- Added ffmpeg to PHP 7.4 backend

### Changed
- Changed default backend to PHP 7.4

## [0.12.2] - 2020-01-08

### Added
- Added proper localtunnel support and OPS_LOCALTUNNEL_HOST config option

## [0.12.1] - 2019-12-09

### Fixed
- Updated mkcert for OSX Catalina

## [0.12.0] - 2019-12-06

### Removed
- PHP 5.6 Support

### Added
- LDAP Extension to PHP 7.2 and 7.3

## [0.11.3] - 2019-08-08

### Fixed
- Issue with cli docs and bash 3
- Issue with an older version of awk

## [0.11.2] - 2019-08-07

### Fixed
- Issue with Dashboard and linked containers
- Issue with `OPS_PROJECT_REMOTE_OPS` config

### Added
- `mariadb list` command
- `psql list` command

## [0.11.1] - 2019-08-06

### Changed
- Modernize dashboard code

### Fixed
- Bug with `ops system install` and new dashboard code
- Bug with X-Ops-Project-Name header

## [0.11.0] - 2019-08-06

### Changed
- Upgraded all php7 images to latest minor versions
- dnsmasq now a default base service

### Fixed
- Remote ops database syncing
- IP whitelisting for services

### Added
- `mysql-client` and `postgres-client` to all php7 images

## [0.9.4] - 2019-04-09

### Added
- Added .env helper `ops env`

## [0.9.3] - 2019-04-05

### Fixed
- Issue with uninstalling rootCA on macOS

## [0.9.2] - 2019-03-13

### Fixed
- Domains with dashes now work. Caused by Lua regex issue.
- PHP 7.3 beta extensions upgraded to stable versions (xdebug, sqlsrv, pdo_sqlsrv)
- Postgres remote DB sync

### Changed
- PHP 5.3.39 upgraded to PHP 5.3.40
- PHP 7.1.25 upgraded to PHP 7.1.27
- PHP 7.2.13 upgraded to PHP 7.2.16
- PHP 7.3.1 upgraded to PHP 7.3.3

### Added
- BC Math extension to all PHP versions
- Command hooks for use in project-level ops-commands.sh file
- Push docker images script


## [0.9.1] - 2019-01-07

### Changed
- Reverted default backend to `apache-php71`
- Active backends now `apache-php71`, `apache-php72`, `apache-php73`, and `apache-php56`

## [0.9.0] - 2019-01-06

### Changed
- Default backend now `apache-php73`
- Active backends now `apache-php73` and `apache-php56`. Set OPS_BACKENDS to enable others.

### Added
- PHP 7.3 support (apache-php73 backend)
- `OPS_BACKENDS` global config option
- enabled macro and http2 modules for all apache backends
- Lots of documentation about global config options

### Fixed
- Fied bug where `ops system config` wouldn't work
- Bug where lua code would break on non-standard HTTP ports
- Vagrant provisioning script



## [0.8.5] - 2018-12-06

### Fixed
- Bug typo that caused the dashboard to not restart properly.

## [0.8.4] - 2018-12-06

### Added
- Configurable ability to have a projects accept 2nd-level subdomains.
- `OPS_SHELL_USER` global config option
- `ops shell` optionally takes a command to execute

### Fixed
- Added `--remove-orphans` flag to `ops link`

## [0.8.0] - 2018-09-19

### Removed
- PHP Version URLs. Use `OPS_PROJECT_BACKEND` dotenv var
- `OPS_PROJECT_PHP_VERSION` dotenv var
- Custom self signed cert generator

### Added
- "Remote" mode with Let's Encypt DNS challenge support
- nginx/openresty proxy for reading dotenv
- `OPS_DEFAULT_DOCROOT` global config option
- `OPS_DEFAULT_BACKEND` global config option
- `OPS_ADMIN_AUTH` global config option for remote mode
- `OPS_PROJECT_BACKEND` project config option
- `OPS_PROJECT_DOCROOT` project config option
- `OPS_PROJECT_BASIC_AUTH` project config option
- `OPS_PROJECT_BASIC_AUTH_FILE` project config option
- Version tracking through ~/.ops/VERSION file

### Fixed
- `mariadb import` and `psql import` STDIN handling
- Big refactor of script variables
- `ops sync` db vars now optional (host, name, port, pass)

## [0.7.5] - 2018-08-30

### Added
- php 5.6: Added php zip extension and webgrind

## [0.7.4] - 2018-08-23

### Added
- **dashboard** Proper php links for 5.6, 7.1, and 7.2

## [0.7.3] - 2018-08-23

### Fixed
- **dashboard** fixed php NOTICE

## [0.7.2] - 2018-08-15

### Added
- Lots of php 5.6 extensions

### Fixed
- `psql import` IF EXISTS clause

### Changed
- php `upload_max_filesize` and `post_max_size` are now 100M
- php `display_errors` and `display_startup_errors` are now on

## [0.7.1] - 2018-08-14

### Fixed
- **dashboard** project links respect custom php version
- `ops shell` respects custom php version

## [0.7.0] - 2018-08-13

### Added
- php image dockerfiles moved to ops repo
- official ops docker images: imarcagenct/ops-apache-php*
- php 5.6 support
- php 7.2 support

## [0.6.1] - 2018-08-03

### Fixed
- `psql import` now works properly
- `OPS_PROJECT_REMOTE_DB_HOST` fixed for mariadb/mysql

### Added
- `OPS_PROJECT_REMOTE_DB_PASSWORD` added for mariadb/mysql
- `OPS_PROJECT_REMOTE_DB_PORT` added for mariadb/mysql

## [0.6.0] - 2018-06-22

### Added
- **dashboard** tooltip for 'live' project badge
- `ops sync` command
- `ops system refresh-certs` command
- `ops system refresh-config` command
- `ops system refresh-services` command
- `ops mariadb create` command
- `ops psql create` command

### Changed
- `ops psql` is now `ops psql cli`
- `ops psql-import` is now `ops psql import`
- `ops psql-export` is now `ops psql export`
- `ops mariadb` is now `ops mariadb cli`
- `ops mariadb-import` is now `ops mariadb import`
- `ops mariadb-export` is now `ops mariadb export`

## [0.5.0] - 2018-05-24

### Added
- Changelog!

### Changed
- `ops shell` now runs bash as www-data within the running container
