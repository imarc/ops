<?php namespace Imarc\Ops\Dashboard\Providers;

use Imarc\Ops\Dashboard\Providers\ProviderAbstract;
use League\Plates\Engine;

class PlatesProvider extends ProviderAbstract
{
    public function get()
    {
        return new Engine($this->config()['path']);
    }
}
