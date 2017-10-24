#!/usr/bin/env node
'use strict'

var yargs = require('yargs');
var helpers = require('./helpers');

const NODE_IMAGE="node:8.7.0"
const COMPOSER_IMAGE="composer:1.1"

let argv = yargs
    .usage("$0 command")

    .command(
        'npm',
        `run npm (${NODE_IMAGE})`,
        (yargs) => {
            let args = helpers.shiftArgs(yargs);

            helpers.dockerRunTransient([
                '-ti',
                '-v', `${process.cwd()}:/usr/src/app`,
                '-w', '/usr/src/app',
                '--entrypoint', 'npm',
                NODE_IMAGE,
                ...args
            ]);

            process.exit();
        }
    )

    .command(
        'composer',
        `run composer (${COMPOSER_IMAGE})`,
        () => {
            let args = helpers.shiftArgs(yargs);

            helpers.dockerRunTransient([
                '-ti',
                '-v', `${process.cwd()}:/usr/src/app`,
                '-w', '/usr/src/app',
                COMPOSER_IMAGE,
                ...args
            ]);

            process.exit();
        }
    )
    .help()
    .argv;

yargs.showHelp();
