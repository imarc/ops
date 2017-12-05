#!/usr/bin/env node
'use strict'

var fs = require('fs');
var yargs = require('yargs');
var stringArgv = require('string-argv');
var helpers = require('./helpers');
var commands = require('./commands');
var prefixer = require('color-prefix-stream');
var pump = require('pump');
var spawn = require('child_process').spawn;
var spawnSync = require('child_process').spawnSync;
//var spawnSync = require('./spawn');

var commandQueue = [];

var opsfile = {
    commands: {}
};

// load local opsfile

if (fs.existsSync(`${process.cwd()}/opsfile.js`)) {
    opsfile = Object.assign(opsfile, require(`${process.cwd()}/opsfile.js`));
}

// set constants

const WILDCARD_ARG   = "$@"

// build commands

var app = yargs
    .usage("$0 command");

app.command(
    ['npm', 'n'],
    `run npm`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.npm(yargs.argv.spawnFn, args, yargs.argv.io);
    }
);

app.command(
    ['composer', 'c'],
    `run composer`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.composer(yargs.argv.spawnFn, args, yargs.argv.io);
    }
);

app.command(
    ['docker-compose', 'dc'],
    `run docker-compose`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.dockerCompose(yargs.argv.spawnFn, args, yargs.argv.io);
    }
);

app.command(
    ['exec', 'e'],
    `run exec for a docker-compose service`,
    function (yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.exec(yargs.argv.spawnFn, args, yargs.argv.io);
    }
);


// build dynamic opsfile commands

Object.keys(opsfile.commands).forEach((name) => {
    app.command(name, '', (yargs) => {
        yargs.help(false);

        let args = helpers.shiftCommandFromArgs(yargs);

        let commands = opsfile.commands[name].map((command) => {
            command = stringArgv(command);
            let spawnFn = spawn;

            if (command[0] === 'sync') {
                spawnFn = spawnSync;
                command.shift();
            }

            let index = command.findIndex((i) => {
                return i === WILDCARD_ARG;
            });

            if (index > -1) {
                command.splice(index, 1, ...args);
            }

            return {
                argv: command,
                spawnFn
            };
        });

        commandQueue.unshift(...commands);
    });
});

// use help

app.help('help').alias('help', 'h');

// parse/run initial command

app.parse(process.argv, {
    command: process.argv,
    spawnFn: spawnSync,
    io: 'inherit'
});

// parse/run any queued up child commands

var command;
while (command = commandQueue.shift()) {
    app.parse(command.argv, {
        command: command.argv,
        spawnFn: command.spawnFn,
        io: 'inherit'
    });
};
