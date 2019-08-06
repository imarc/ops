<?php require dirname(__DIR__) . '/vendor/autoload.php';

$dashboard = new Imarc\Ops\Dashboard\Dashboard(include(dirname(__DIR__) . '/config/config.php'));
$dashboard->run();

?>
