'use strict'

let helpers = require('./helpers');
var spawn   = require('child_process').spawnSync;

const NODE_IMAGE     = "node:8.7.0"
const COMPOSER_IMAGE = "composer:1.1"
const DOCKERCOMPOSE_IMAGE = "docker/compose:1.16.1"
//const WAIT_FOR_IT_IMAGE = "willwill/wait-for-it:latest"

let commands = {
    waitForIt(args) {

    },

    exec(args, stdio) {
        let output = this.dockerCompose(['ps', '-q', args.shift()]);
        let containerId = output.stdout.toString('utf8').trim();

        return helpers.dockerExec([containerId, ...args], stdio);
    },

    dockerCompose(args, stdio) {
        return helpers.dockerRunTransient([
            '-v', `${process.cwd()}:${process.cwd()}`,
            '-w', process.cwd(),
            '-v', '/var/run/docker.sock:/var/run/docker.sock',
            DOCKERCOMPOSE_IMAGE,
            ...args
        ], stdio);
    },

    npm(args, stdio) {
        return helpers.dockerRunTransient([
            '-v', `${process.cwd()}:/usr/src/app`,
            '-w', '/usr/src/app',
            '--entrypoint', 'npm',
            NODE_IMAGE,
            ...args
        ], stdio);
    },

    composer(args, stdio) {
        return helpers.dockerRunTransient([
            '-v', `${process.cwd()}:/usr/src/app`,
            '-w', '/usr/src/app',
            COMPOSER_IMAGE,
            ...args
        ], stdio);
    },
};

module.exports = commands;
