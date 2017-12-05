'use strict';

var userid = require('userid');
var username = require('username').sync();
var prefixer = require('color-prefix-stream');

module.exports = {
    isLinux: ['linux', 'freebsd'].includes(process.platform),
    isDarwin: ['darwin'].includes(process.platform),
    isWindows: ['win32'].includes(process.platform),

    shiftCommandFromArgs(yargs) {
        let index = yargs.argv.command.findIndex(
            x => x === yargs.getContext().commands[0]
        );

        return yargs.argv.command.slice(index + 1);
    },

    dockerExec(spawnFn, args, stdio) {
        return this.dockerCommand(spawnFn, 'exec', args, stdio);
    },

    dockerRun(spawnFn, args, stdio) {
        return this.dockerCommand(spawnFn, 'run', args, stdio);
    },

    dockerRunTransient(spawnFn, args, stdio) {
        return this.dockerCommand(spawnFn, 'run', [ '--rm', ...args ], stdio);
    },

    dockerCommand(spawnFn, command, args, stdio) {
        let optional = [];

        if (stdio === 'inherit') {
            optional.unshift(
                '-ti'
            );
        }

        if (this.isLinux) {
            optional.unshift(
                '-u', `${userid.uid(username)}:${groupid.gif(username)}`
            );
        }

        args = [ command, ...optional, ...args ];

        return spawnFn('docker', args, {
            cwd: process.cwd(),
            env: process.env,
            shell: true,
            stdio
        });

        return result;
    }
};
