<?php namespace Imarc\Ops\Dashboard\Helpers;

use GuzzleHttp\Client;
use Symfony\Component\Dotenv\Dotenv;
use GuzzleHttp\Exception\ConnectException;

function getDockerContainers()
{
    $json = [
        'success' => false,
    ];

    try {
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
            $hostname = $rawContainer['Labels']['ops.hostname'] ?? null;

            $container['id'] = $id;
            $container['project'] = $project;
            $container['hostname'] = $hostname;
            $container['service'] = $service;
            $container['state'] = $rawContainer['State'];
            $container['status'] = $rawContainer['Status'];
            $container['logs_link'] = sprintf('https://portainer.ops.imarc.io/#/containers/%s/logs', $id);
            $container['console_link'] = sprintf('https://portainer.ops.imarc.io/#/containers/%s/console', $id);

            $containers[$project][$service] = $container;

            $json['success'] = true;
            $json['message'] = 'containers found';
            $json['data'] = $containers;
        }
    } catch (ConnectException $e) {
        $json['message'] = $e->getMessage();
    }

    return $json;
}

function parseEnv($dir)
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

/**
 * Worktrees of a project that nginx serves at <worktree>.<project>.OPS_DOMAIN.
 * Mirrors the gitdir lookup in nginx.conf.
 */
function getWorktrees($dir, $sitesDir)
{
    $sitesDir = rtrim($sitesDir, '/');
    $worktrees = [];

    foreach (glob($dir . '/.git/worktrees/*/gitdir') as $file) {
        $name = basename(dirname($file));

        if (!preg_match('/^[a-zA-Z0-9_-]+$/', $name)) {
            continue;
        }

        $path = preg_replace('#/\.git$#', '', trim(strtok(file_get_contents($file), "\n")));

        if ($path === '' || $path[0] !== '/') {
            // relative to the gitdir file's folder (worktree.useRelativePaths)
            $path = realpath(dirname($file) . '/' . $path);

            if ($path === false || strpos($path, '/var/www/html/') !== 0) {
                continue;
            }
        } elseif (strpos($path, $sitesDir . '/') === 0 && strpos($path, '..') === false) {
            $path = '/var/www/html' . substr($path, strlen($sitesDir));
        } else {
            continue;
        }

        if (is_dir($path)) {
            $worktrees[] = $name;
        }
    }

    sort($worktrees);

    return $worktrees;
}
