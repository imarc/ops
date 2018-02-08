'use strict';

var userid = require('userid');
var username = require('username').sync();
var prefixer = require('color-prefix-stream');
var execa = require('execa');

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

    dockerExec(args, stdio) {
        return this.dockerCommand(['exec', ...args], stdio);
    },

    dockerRun(args, stdio) {
        return this.dockerCommand(['run', ...args], stdio);
    },

    dockerRunTransient(args, stdio) {
        return this.dockerCommand(['run', '--rm', ...args ], stdio);
    },

    dockerCommand(args, stdio = 'inherit') {
        let optional = [];
        let command = args.shift();

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

        return execa('docker', args, {
            //detached: true,
            killSignal: 'SIGINT',
            //timeout: 4,
            stdio
        }).catch(() => {
            // process.exit();
        });
    }
};
