#!/usr/bin/env node
'use strict'

var fs = require('fs');
var yargs = require('yargs');
var stringArgv = require('string-argv');
var helpers = require('./helpers');
var cmds = require('./commands');

const outdent = require('outdent');
const download = require('download-git-repo')
const os = require('os');
const wrap = require('word-wrap');
//var spawnSync = require('./spawn');
//
const home = os.homedir();

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

//

let commands = {
    "npm": cmds.npm,
    "exec": cmds.exec,
    "docker": cmds.docker,
    "docker-compose": cmds.dockerCompose,
    "composer": cmds.composer,

    "shell": () => {
        return processCommand(args.shift(), args, 'inherit');
    },

    "help": () =>  {
        console.log();

        console.log(outdent`
            Usage: ops <command>

            Where <command> is one of:
        `);

        console.log(wrap(
            Object.keys(commands).sort().join(", "),
            { width: 45, indent: '    ' }
        ));

        console.log();

        return Promise.resolve();
    }
};

// add opsfile commands

Object.keys(opsfile.commands).forEach(cmd => {
    commands[cmd] = opsfile.commands[cmd];
});

// cmds

let command = yargs.argv._[0];
let args = yargs.argv._.slice(1);

let procs = [];

let processCommand = (command, args = [], stdio=['ignore', 1, 2]) => {
    if (typeof(command) === 'function') {
       let proc = command(args, stdio);
       procs.push(proc);
       return proc;
    }
    if (typeof(commands[command]) === 'function') {
       return commands[command](args);
    }

    command = [command];

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

processCommand(command, args);

let exit = () => {
    procs.forEach(i => () => {
        if (i !== undefined) {
            // http://azimi.me/2014/12/31/kill-child_process-node-js.html
            process.kill(-i.pid, 'SIGINT');
        }
    });

    setTimeout(() => {
        process.exit(0);
    }, 1000);
};

//process.on('SIGINT', exit);
//process.on('SIGTERM', exit);
