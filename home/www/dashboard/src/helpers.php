<?php
namespace OpsDashboard;

use GuzzleHttp\Client;
use Symfony\Component\Dotenv\Dotenv;

function get_containers()
{
    $client = new Client([
        'base_uri' => 'http://portainer:9000/api/',
    ]);

    $parsedBody = json_decode($client->request('GET', 'endpoints/1/docker/v1.24/containers/json')->getBody(), true);

    $containers = [];

    foreach($parsedBody as $rawContainer) {
        if (!isset($rawContainer['Labels']['ops.project'])) {
            continue;
        }

        $id = $rawContainer['Id'];
        $project = $rawContainer['Labels']['ops.project'];
        $service = $rawContainer['Labels']['ops.service'] ?? $rawContainer['Labels']['com.docker.compose.service'] ?? $id;

        $container['id'] = $id;
        $container['project'] = $project;
        $container['service'] = $service;
        $container['state'] = $rawContainer['State'];
        $container['status'] = $rawContainer['Status'];
        $container['logs_link'] = sprintf('https://portainer.ops.imarc.io/#/containers/%s/logs', $id);
        $container['console_link'] = sprintf('https://portainer.ops.imarc.io/#/containers/%s/console', $id);

        $containers[$project][$service] = $container;
    }

    return $containers;
}

function parse_dotenv($dir)
{
    $dotenv = new Dotenv();

    $paths = [
        $dir . '/.env.example',
        $dir . '/.env'
    ];

    $values = [];

    foreach ($paths as $path) {
        if (!is_readable($path) || is_dir($path)) {
            continue;
        }

        $values = array_merge($values, $dotenv->parse(file_get_contents($path), $path));
    }

    return $values;
}
