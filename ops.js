#!/usr/bin/env node
'use strict'

var yargs = require('yargs');
var spawn = require('child_process').spawnSync;

const NODE_IMAGE="node:8.7.0"
const COMPOSER_IMAGE="composer:1.1"

let argv = yargs
    .usage("$0 command")

    .command(
        'npm',
        `run npm (${NODE_IMAGE})`,
        (yargs) => {
            let index = process.argv.findIndex(x => x === yargs.getContext().commands[0]);
            let args = process.argv.slice(index + 1);
            let cwd = process.cwd();
            let options = {};

            args.unshift(
                'run',
                '--rm',
                '-t', '-i',
                '-v', `${cwd}:/usr/src/app`,
                '-w', '/usr/src/app',
                '--entrypoint', 'npm',
                NODE_IMAGE
            );

            options.cwd = cwd;
            options.env = process.env;
            options.shell = true;
            options.stdio = 'inherit';

            spawn('docker', args, options);

            process.exit();
        }
    )

    .command(
        'composer',
        `run composer (${COMPOSER_IMAGE})`,
        () => {
            let index = process.argv.findIndex(x => x === yargs.getContext().commands[0]);
            let args = process.argv.slice(index + 1);
            let cwd = process.cwd();
            let options = {};

            args.unshift(
                'run',
                '--rm',
                '-t', '-i',
                '-v', `${cwd}:/usr/src/app`,
                '-w', '/usr/src/app',
                COMPOSER_IMAGE
            );

            options.cwd = cwd;
            options.env = process.env;
            options.shell = true;
            options.stdio = 'inherit';

            spawn('docker', args, options);

            process.exit();
        }
    )
    .help()
    .argv;

yargs.showHelp()
