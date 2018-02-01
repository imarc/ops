'use strict';

var execa = require('execa');

let procs = [];
procs.push(execa('sleep 2 && echo done', [], { shell: true, stdio: 'inherit' }));
procs.push(execa('sleep 5 && echo done', [], { shell: true, stdio: 'inherit' }));

Promise.all(procs).then(() => {
    procs.push(execa('sleep 5 && echo done', [], { shell: true, stdio: 'inherit' }));
});
