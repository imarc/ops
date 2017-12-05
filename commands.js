'use strict';

let helpers = require('./helpers');
var spawn = require('child_process').spawn;
var spawnSync = require('child_process').spawnSync;
let os = require('os');

const NODE_IMAGE     = "node:8.7.0"
const COMPOSER_IMAGE = "composer:2.1"
const DOCKERCOMPOSE_IMAGE = "docker/compose:1.16.1"

let commands = {

    exec(spawnFn, args, stdio) {
        let output = this.dockerCompose(spawnSync, ['ps', '-q', args.shift()]);
        let containerId = output.stdout.toString('utf8').trim();

        return helpers.dockerExec(spawnFn, [containerId, ...args], stdio);
    },

    dockerCompose(spawnFn, args, stdio) {
        return helpers.dockerRunTransient(spawnFn, [
            '-v', `${process.cwd()}:${process.cwd()}`,
            '-w', process.cwd(),
            '-v', '/var/run/docker.sock:/var/run/docker.sock',
            DOCKERCOMPOSE_IMAGE,
            ...args
        ], stdio);
    },

    npm(spawnFn, args, stdio) {
        return helpers.dockerRunTransient(spawnFn, [
            '-v', `${os.homedir()}:${os.homedir()}:ro`,
            '-v', `${process.cwd()}:/usr/src/app`,
            '-w', '/usr/src/app',
            '--entrypoint', 'npm',
            NODE_IMAGE,
            ...args
        ], stdio);
    },

    composer(spawnFn, args, stdio) {
        return helpers.dockerRunTransient(spawnFn, [
            '-v', `${process.cwd()}:/usr/src/app`,
            '-w', '/usr/src/app',
            COMPOSER_IMAGE,
            ...args
        ], stdio);
    },
};

module.exports = commands;
