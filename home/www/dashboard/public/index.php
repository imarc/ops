<?php
$domain = $_ENV['OPS_DOMAIN'];
?>
<!doctype html>
<html lang="">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="x-ua-compatible" content="ie=edge">
        <title>Ops Dashboard</title>
        <meta name="description" content="">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    </head>
    <body>
        <h1>Ops Dashboard</h1>

        <h2>Services</h2>

        <ul>
            <li>
                <a href="https://adminer.ops.<?= $domain ?>">Adminer</a>
                <ul>
                    <li><a href="https://adminer.ops.<?= $domain ?>/?server=mariadb&amp;username=root">MySQL</a></li>
                    <li><a href="https://adminer.ops.<?= $domain ?>/?pgsql=postgres&amp;username=postgres">PostgreSQL</a></li>
                </ul>
            </li>
            <li>
                <a href="https://mailhog.ops.<?= $domain ?>">Mailhog</a>
            </li>
            <li>
                <a href="https://minio.ops.<?= $domain ?>">Minio</a>
            </li>
            <li>
                <a href="https://ops.<?= $domain ?>:8080/dashboard/#/health">Traefik</a>
            </li>
            <li>
                <a href="https://portainer.ops.<?= $domain ?>">Portainer</a>
            </li>

            <li><a href="/phpinfo.php">PHP Info</a></li>
        </ul>

        <h2>Sites</h2>

        <p><em>Only valid site directories will show. Dirs must only contain letters, numbers, and dashes.</em></p>

        <ul>

        <?php
        foreach(glob('/var/www/html/*', GLOB_ONLYDIR) as $dir) {
            $site = str_replace('/var/www/html/', '', $dir);
            if (!preg_match('/^[a-z][a-z0-9-]*$/', $site)) {
                continue;
            }
            ?>

            <li>
                <a href="https://<?= $site ?>.<?= $domain ?>"><?= $site ?></a>
            </li>

            <?php
        }
        ?>

        </ul>
    </body>
</html>
