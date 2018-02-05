#!/usr/bin/env node
'use strict'

var fs = require('fs');
var yargs = require('yargs');
var stringArgv = require('string-argv');
var helpers = require('./helpers');
var cmds = require('./commands');
var outdent = require('outdent');

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

// var app = yargs
// .usage("$0 command");

/*

app.command(
    ['npm', 'n'],
    `run npm`,
    function(yargs) {
        yargs.help(false);
    }
);

app.command(
    ['composer', 'c'],
    `run composer`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.composer(args, yargs.argv.io);
    }
);

app.command(
    ['docker-compose', 'dc'],
    `run docker-compose`,
    function(yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.dockerCompose(args, yargs.argv.io);
    }
);

app.command(
    ['exec', 'e'],
    `run exec for a docker-compose service`,
    function (yargs) {
        yargs.help(false);
        let args = helpers.shiftCommandFromArgs(yargs);
        commands.exec(args, yargs.argv.io);
    }
);

*/

let commands = {
    "npm": cmds.npm,
    "exec": cmds.exec,
    "docker": cmds.docker,
    "docker-compose": cmds.dockerCompose,
    "composer": cmds.composer,

    "npm2": [
        [ "npm help", "npm help" ],
    ],

    "help": () =>  {
        let cmdString = Object.keys(commands).sort().join(", ");

        console.log(outdent`
            Usage: ops <command>

            Where <command> is one of:
              ${cmdString}
        `);
    }
};

// add opsfile commands

Object.keys(opsfile.commands).forEach(cmd => {
    commands[cmd] = opsfile.commands[cmd];
});

let command = yargs.argv._[0];
let args = yargs.argv._.slice(1);

let processCommand = (command, args = []) => {
    if (typeof(command) === 'function') {
       return command(args);
    }

    if (typeof(command) === 'string') {
        command = [command];
    }

    return command.reduce((prev, current) => {
        return prev.then(() => {
            if (!Array.isArray(current)) {
                current = [current];
            }

            return Promise.all(current.map(cmd => {
                if (typeof(cmd) === 'string') {
                    let newArgs = stringArgv(cmd);
                    cmd = commands[newArgs.shift()];
                    args = newArgs;
                }

                return processCommand(cmd, args);
            }));
        });
   }, Promise.resolve());
};

processCommand(command);

/*
if (!command) {
}
*/

// build dynamic opsfile commands

/*
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

            return {
                argv: command,
            };
        });

        commandQueue.unshift(...commands);
    });
});

// use help

//app.help('help').alias('help', 'h');

// parse/run initial command

app.parse(process.argv, {
    command: process.argv,
    io: 'inherit'
}, (err, argv, output) => {
    console.log(output);
});

// parse/run any queued up child commands

while (command = commandQueue.shift()) {
    app.parse(command.argv, {
        command: command.argv,
        io: 'inherit'
    });
};
*/
