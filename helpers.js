
var spawn = require('child_process').spawnSync;
var userid = require('userid');
var username = require('username').sync();

module.exports = {
    isLinux: ['linux', 'freebsd'].includes(process.platform),
    isDarwin: ['darwin'].includes(process.platform),
    isWindows: ['win32'].includes(process.platform),

    shiftArgs(yargs) {
        let index = process.argv.findIndex(
            x => x === yargs.getContext().commands[0]
        );

        return process.argv.slice(index + 1);
    },


    dockerRun(args, optional) {
        optional = optional || [];

        if (this.isLinux) {
            optional.shift(
                '-u', userid.uid(username),
                '-g', groupid.gif(username)
            );
        }

        args = [ 'run', ...optional, ...args ];

        spawn('docker', args, {
            cwd: process.cwd(),
            env: process.env,
            shell: true,
            stdio: 'inherit'
        });
    },

    dockerRunTransient(args, optional) {
        this.dockerRun([ '--rm', ...args ], optional);
    }
};
