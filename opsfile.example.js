module.exports = {
    commands: {
        install: [
            'npm install',
            'composer install --ignore-platform-reqs'
        ],

        update: [
            'npm update',
            'composer update'
        ],

        dev: [
            'docker-compose up -d',
            'npm run watch'
        ],

        start: [
            'docker-compose down -v',
        ],

        stop: [
            'docker-compose stop'
        ],
    }
};
