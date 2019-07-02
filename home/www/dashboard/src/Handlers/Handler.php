<?php namespace Imarc\Ops\Dashboard\Handlers;

use League\Plates\Engine;
use Psr\Http\Server\RequestHandlerInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Zend\Diactoros\Response;

abstract class Handler implements RequestHandlerInterface
{
    private $templates;
    private $response;

    public function __construct(array $config, Engine $templates)
    {
        $this->config = $config;
        $this->templates = $templates;
        $this->response = new Response();
    }

    public function view($path, $data = [], $status = 200)
    {
        $this->response = $this->response->withStatus($status);
        $this->response->getBody()->write($this->templates->render($path, $data));

        return $this->response;
    }

    abstract public function handle(ServerRequestInterface $request): ResponseInterface
    {

    }
}
