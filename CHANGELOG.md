# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
