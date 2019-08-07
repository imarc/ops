<?php $this->layout('_layout', ['version' => $version]) ?>

<div class="row">
    <div class="col-md">
        <h2>Projects</h2>

        <ul>
        <?php foreach (glob('/var/www/html/*', GLOB_ONLYDIR) as $dir):
            $site = str_replace('/var/www/html/', '', $dir);
            if (!preg_match('/^[a-z][a-z0-9-]*$/', $site)) {
                continue;
            }

            try {
                $env = Imarc\Ops\Dashboard\Helpers\parseEnv($dir);
            } catch (Exception $e) {
                $errors = ['error parsing .env files'];
            }

            $requiresLink = file_exists($dir . '/ops-compose.yml');
            ?>

            <li>
                <?php if ($requiresLink && !isset($containers['data'][$site])): ?>
                    <?= $site ?>
                    <span
                        class="badge badge-secondary"
                        data-toggle="tooltip"
                        data-placement="right"
                        data-html="true"
                        title="Linked project container(s) required. Run <code>ops link</code> In project directory.">
                            link
                    </span>
                <?php elseif ($requiresLink && isset($containers['data'][$site])): ?>
                    <?= $site ?>
                    <span
                        class="badge badge-primary"
                        data-toggle="tooltip"
                        data-placement="right"
                        data-html="true"
                        title="Linked project container(s) listed below">
                            linked
                    </span>

                <?php else: ?>
                    <a class="site" href="https://<?= $site ?>.<?= $domain ?>"><?= $site ?></a>
                <?php endif ?>


                <?php if (isset($containers['data'][$site])): ?>
                    <ul>
                        <?php foreach ($containers['data'][$site] as $service => $details): ?>


                            <li>
                                <?php if ($details['hostname']): ?>
                                    <a href="https://<?= $details['hostname'] ?>"><?= $service ?></a>

                                <?php else: ?>
                                    <?= $service ?>
                                <?php endif ?>

                                <?= sprintf(
                                    '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                                    $details['logs_link'],
                                    $details['console_link'],
                                )?>
                            </li>
                    <?php endforeach ?>
                    </ul>
                <?php endif ?>
            </li>
        <?php endforeach ?>
        </ul>

        <p class="note"><em>Only valid site directories within <strong><?= $sitesDir ?></strong> will show. Site directories must only contain letters, numbers, and dashes.</em></p>
    </div>

    <div class="col-md databases">
        <h2>Databases</h2>
        <?php if ($databases['mariadb'] !== false): ?>
            <header>
                <h3>MariaDB</h3>
                <small>
                    /
                    <a href="https://adminer.ops.<?= $domain ?>/?server=mariadb&username=root&database=">create db</a>
                </small>
            </header>

            <ul>
                <?php $count = 0 ?>
                <?php foreach ($databases['mariadb'] as $db) {
                    if (in_array($db[0], ['mysql', 'information_schema', 'performance_schema'])) {
                        continue;
                    } ?>

                    <li>
                        <?php
                        $link = "https://adminer.ops.${domain}/?server=mariadb&username=root&db=" . $db[0];
                    echo sprintf('<a href="%s">%s</a>', $link, $db[0]);

                    $sqlLink = "https://adminer.ops.${domain}/?server=mariadb&username=root&sql=&db=" . $db[0];
                    echo sprintf('<small> / <a href="%s">query</a></li></small>', $sqlLink); ?>
                    </li>

                    <?php
                    $count++;
                } ?>
                <?php if ($count === 0): ?>
                    <li><em>None</em></li>
                <?php endif ?>
            </ul>
        <?php endif ?>

        <?php if ($databases['postgres'] !== false): ?>
            <header>
                <h3>Postgres</h3>
                <small>
                    /
                <a href="https://adminer.ops.<?= $domain ?>/?pgsql=postgres&username=postgres&database=">create db</a>
                </small>
            </header>

            <ul>
            <?php $count = 0 ?>
            <?php foreach ($databases['postgres'] as $db): ?>
                <?php if (in_array($db['name'], ['postgres'])) {
                    continue;
                } ?>

                <li>
                    <?php $link = "https://adminer.ops.${domain}/?pgsql=postgres&username=postgres&ns=public&db=" . $db['name'] ?>
                    <?= sprintf('<a href="%s">%s</a>', $link, $db['name']) ?>

                    <?php $sqlLink = "https://adminer.ops.${domain}/?pgsql=postgres&username=postgres&ns=public&sql=&db=" . $db['name'] ?>
                    <?= sprintf('<small> / <a href="%s">query</a></li></small>', $sqlLink) ?>
                </li>
                <?php $count++ ?>
            <?php endforeach ?>

            <?php if ($count === 0): ?>
                <li><em>None</em></li>
            <?php endif ?>
            </ul>
        <?php endif ?>
    </div>
    <div class="col-md">

        <h2>Tools</h2>

        <ul>
            <?php foreach ($backends as $key => $name): ?>
                    <?php if (isset($containers['data']['ops'][$key])): ?>
                    <li>
                        <?= $name ?>
                        <?= sprintf(
                            '<small> / <a href="%s">logs</a> / <a href="%s">console</a></small>',
                            $containers['data']['ops']['apache-php73']['logs_link'],
                            $containers['data']['ops']['apache-php73']['console_link']
                        ) ?>
                    </li>
                    <?php endif ?>
            <?php endforeach ?>

            <?php if (isset($containers['data']['ops']['adminer'])): ?>
            <li>
                <a href="https://adminer.ops.<?= $domain ?>">Adminer</a>

                <?= sprintf(
                    '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                    $containers['data']['ops']['adminer']['logs_link'],
                    $containers['data']['ops']['adminer']['console_link']
                ) ?>

                <ul>
                    <?php if ($databases['mariadb']): ?>
                    <li>
                        <a href="https://adminer.ops.<?= $domain ?>/?server=mariadb&amp;username=root">MariaDB</a>

                        <?= sprintf(
                            '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                            $containers['data']['ops']['mariadb']['logs_link'],
                            $containers['data']['ops']['mariadb']['console_link']
                        ) ?>
                    </li>
                    <?php endif ?>

                    <?php if ($databases['postgres']): ?>
                    <li>
                        <a href="https://adminer.ops.<?= $domain ?>/?pgsql=postgres&amp;username=postgres">PostgreSQL</a>

                        <?= sprintf(
                            '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                            $containers['data']['ops']['postgres']['logs_link'],
                            $containers['data']['ops']['postgres']['console_link']
                        ) ?>
                    </li>
                    <?php endif ?>
                </ul>
            </li>
            <?php endif ?>

                <?php if (isset($containers['data']['ops']['minio'])): ?>
                <li>
                    <a href="https://minio.ops.<?= $domain ?>">Minio</a>

                <?= sprintf(
                    '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                    $containers['data']['ops']['minio']['logs_link'],
                    $containers['data']['ops']['minio']['console_link']
                ) ?>
            </li>
            <?php endif?>

            <?php if (isset($containers['data']['ops']['mailhog'])): ?>
                <li>
                    <a href="https://mailhog.ops.<?= $domain ?>">Mailhog</a>
                    <?= sprintf(
                        '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                        $containers['data']['ops']['mailhog']['logs_link'],
                        $containers['data']['ops']['mailhog']['console_link']
                    ) ?>
                </li>
            <?php endif ?>

            <?php if (isset($containers['data']['ops']['traefik'])): ?>
            <li>
                <a href="https://ops.<?= $domain ?>:8080/dashboard/#/health">Traefik</a>
                <?= sprintf(
                    '<small> / <a href="%s">logs</a> / <a href="%s">console</a> </small>',
                    $containers['data']['ops']['traefik']['logs_link'],
                    $containers['data']['ops']['traefik']['console_link']
                ) ?>
            </li>
            <?php endif ?>

            <li>
                <a href="https://portainer.ops.<?= $domain ?>">Portainer</a>
            </li>
        </ul>
    </div>
</div>
