<?php namespace Imarc\Ops\Dashboard;

use Pimple;
use Imarc\Ops\Dashboard\Handlers\DashboardHandler;
use Psr\Container\ContainerInterface;
use Zend\Diactoros\Response;
use Zend\Diactoros\ServerRequestFactory;
use Zend\HttpHandlerRunner\Emitter\SapiEmitter;
use Zend\HttpHandlerRunner\RequestHandlerRunner;
use Imarc\Ops\Dashboard\Helpers;

class Dashboard
{
    private $config;
    private $container;

    public function __construct($config)
    {
        $this->config = $config;
        $this->container = $this->initContainer();
    }

    public function run()
    {
        $templates = $this->getContainer()->get('templates');
        $handler = new DashboardHandler($this->config, $templates);

        $runner = new RequestHandlerRunner(
            $handler,
            new SapiEmitter(),
            function() {
                return ServerRequestFactory::fromGlobals();
            },
            function() {
                return new Response();
            }
        );

        $runner->run();
    }

    public function getContainer(): ContainerInterface
    {
        return $this->container;
    }

    public function initContainer(): ContainerInterface
    {
        $container = new Pimple\Container();

        foreach ($this->config['providers'] as $key => $details) {
            $provider = new $details['provider']($details['config']);
            $container[$key] = $provider->get();
        }

        return new Pimple\Psr11\Container($container);
    }
}
