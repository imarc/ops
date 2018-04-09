<?php
$domain = $_ENV['OPS_DOMAIN'];
$sitesDir = $_ENV['OPS_SITES_DIR'];
?>
<!doctype html>
<html lang="">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="x-ua-compatible" content="ie=edge">
        <title>Ops Dashboard</title>
        <meta name="description" content="">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
        <link rel="stylesheet" href="/dashboard.css">
    </head>
    <body>
        <div class="navbar">
            <div class="container">
                <h1>Ops Dashboard</h1>
                <a href="https://gitlab.imarc.net/imarc/ops/blob/master/README.md">Documentation</a>
            </div>
        </div>

        <main class="container">
            <div class="row">
                <div class="col-sm">

                    <h2>Services</h2>

                    <ul>
                        <li>
                            <a href="https://adminer.ops.<?= $domain ?>">Adminer</a>
                            <ul>
                                <li><a href="https://adminer.ops.<?= $domain ?>/?server=mariadb&amp;username=root">MariaDB</a></li>
                                <li><a href="https://adminer.ops.<?= $domain ?>/?pgsql=postgres&amp;username=postgres">PostgreSQL</a></li>
                            </ul>
                        </li>
                        <li>
                            <a href="https://minio.ops.<?= $domain ?>">Minio</a>
                        </li>
                        <li>
                            <a href="https://mailhog.ops.<?= $domain ?>">Mailhog</a>
                        </li>
                        <li>
                            <a href="https://ops.<?= $domain ?>:8080/dashboard/#/health">Traefik</a>
                        </li>
                        <li>
                            <a href="https://portainer.ops.<?= $domain ?>">Portainer</a>
                        </li>

                        <li><a href="/phpinfo.php">PHP Info</a></li>
                    </ul>
                </div>
                <div class="col-sm">
                    <h2>Sites</h2>

                    <ul>
                    <?php
                    $sites = [];
                    foreach(glob('/var/www/html/*', GLOB_ONLYDIR) as $dir) {
                        $site = str_replace('/var/www/html/', '', $dir);
                        if (!preg_match('/^[a-z][a-z0-9-]*$/', $site)) {
                            continue;
                        }

                        echo "<li><a class=\"site\" href=\"https://{$site}.{$domain}\">{$site}</a></li>";
                    }
                    ?>
                    </ul>

                    <p class="note"><em>Only valid site directories within <strong><?= $sitesDir ?></strong> will show. Site directories must only contain letters, numbers, and dashes.</em></p>
                </div>
            </div>
        </div>

        <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
    </body>
</html>
