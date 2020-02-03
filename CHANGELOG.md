# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.13.1] - 2019-02-03

### Fixed
- PHP container warnings on dashboard.

## [0.13.0] - 2019-01-08
- Added PHP 7.4
- Added ffmpeg to PHP 7.4
- Updated default backend to PHP 7.4

## [0.12.2] - 2019-01-08

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
