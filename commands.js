'use strict';

let helpers = require('./helpers');
var spawn = require('child_process').spawn;
var spawnSync = require('child_process').spawnSync;
let os = require('os');

const NODE_IMAGE     = "node:8.7.0"
const COMPOSER_IMAGE = "composer:latest"
const DOCKERCOMPOSE_IMAGE = "docker/compose:1.16.1"

let commands = {
    waitfor(args, stdio) {
        return new Promise(resolve => {
            let service = args.shift();

            commands.dockerCompose(['ps', '-q', service], 'pipe').then((output) => {

                console.log(`Waiting for ${service}`);

                let containerId = output.stdout.toString('utf8').trim();
                helpers.dockerExec([containerId, ...args], stdio).then(() => {
                    console.log(`Found ${service}`);
                    resolve();
                });
            });
        });

    },

    shell(args, stdio) {
        return processCommand(args.shift(), args, 'inherit');
    },

    exec(args, stdio) {
        return new Promise(resolve => {
            commands.dockerCompose(['ps', '-q', args.shift()], 'pipe').then((output) => {
                let containerId = output.stdout.toString('utf8').trim();
                resolve(helpers.dockerExec([containerId, ...args], stdio));
            });
        });
    },

    docker(args, stdio) {
        return helpers.dockerCommand(args, stdio);
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
            '-v', `${os.homedir()}:${os.homedir()}:ro`,
            '-v', `${process.cwd()}:/usr/src/app`,
            '-w', '/usr/src/app',
            '--init', // for the PID 1 problem
            '--entrypoint', 'npm',
            '-e', 'NPM_CONFIG_COLOR=always',
            NODE_IMAGE,
            ...args,
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
