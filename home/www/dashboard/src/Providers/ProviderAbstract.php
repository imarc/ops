<?php namespace Imarc\Ops\Dashboard\Providers;

abstract class ProviderAbstract {

    private $config = [];

    public function __construct($config)
    {
        $this->config = $config;
    }


    public function config()
    {
        return $this->config;
    }

    abstract public function get();
}
