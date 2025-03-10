<?php namespace Imarc\Ops\Dashboard\Handlers;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Zend\Diactoros\Response;
use Imarc\Ops\Dashboard\Helpers;
use PDO;

class DashboardHandler extends Handler
{
    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        $data = [
            'containers' => Helpers\getDockerContainers(),
            'domain' => $_ENV['OPS_DOMAIN'],
            'sitesDir' => $_ENV['OPS_SITES_DIR'],
            'version' => $_ENV['OPS_VERSION'],
            'services' => explode(' ', $_ENV['OPS_SERVICES']),
            'databases' => [
                'mariadb' => false,
                'postgres' => false,
                'postgres16' => false,
            ],
            'errors' => [],
            'sites' => [],
            'backends' => [
                'apache-php84' => 'PHP 8.4',
                'apache-php83' => 'PHP 8.3',
                'apache-php82' => 'PHP 8.2',
                'apache-php81' => 'PHP 8.1',
                'apache-php80' => 'PHP 8.0',
                'apache-php74' => 'PHP 7.4',
                'apache-php73' => 'PHP 7.3',
                'apache-php72' => 'PHP 7.2',
            ]
        ];

        if (in_array('mariadb', $data['services'])) {
        	$mariadb = new PDO('mysql:host=mariadb', 'root', null);
        	$data['databases']['mariadb'] = $mariadb->query('SHOW DATABASES');
        }

        if (in_array('postgres', $data['services'])) {
        	$postgres = new PDO('pgsql:host=postgres9;user=postgres');
        	$data['databases']['postgres'] = $postgres->query('SELECT datname AS name FROM pg_database WHERE datistemplate = false');
        }

        if (in_array('postgres16', $data['services'])) {
        	$postgres = new PDO('pgsql:host=postgres16;user=postgres');
        	$data['databases']['postgres16'] = $postgres->query('SELECT datname AS name FROM pg_database WHERE datistemplate = false');
        }

        return $this->view('index', $data);
    }
}
