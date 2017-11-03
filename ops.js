#!/usr/bin/env node
'use strict'

var fs = require('fs');
var yargs = require('yargs');
var stringArgv = require('string-argv');
var helpers = require('./helpers');
var commands = require('./commands');
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
        commands.npm(args);
    }
);

app.command(
    ['composer', 'c'],
    `run composer`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.composer(args);
    }
);

app.command(
    ['docker-compose', 'dc'],
    `run docker-compose`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.dockerCompose(args);
    }
);

// build dynamic opsfile commands

Object.keys(opsfile.commands).forEach((name) => {
    app.command(name, '', (yargs) => {
        yargs.help(false);

        let args = helpers.shiftCommandFromArgs(yargs);

        let commands = opsfile.commands[name].map((command) => {
            command = stringArgv(command);

            let index = command.findIndex((i) => {
                return i === WILDCARD_ARG;
            });

            if (index > -1) {
                command.splice(index, 1, ...args);
            }

            return command;
        });

        commandQueue.unshift(...commands);
    });
});

// use help

app.help('help').alias('help', 'h');

// parse/run initial command

app.parse(process.argv, { command: process.argv });

// parse/run any queued up child commands

var command;
while (command = commandQueue.shift()) {
    app.parse(command, { command });
};
