#!/usr/bin/env bash
set -euo pipefail

MOODLE_DIR="/var/www/html"
MOODLEDATA_DIR="${MOODLE_DATA_ROOT:-/var/moodledata}"

: "${MOODLE_DB_TYPE:=mariadb}"
: "${MOODLE_DB_HOST:=}"
: "${MOODLE_DB_PORT:=3306}"
: "${MOODLE_DB_NAME:=}"
: "${MOODLE_DB_USER:=}"
: "${MOODLE_DB_PASS:=}"

if [[ -z "${MOODLE_WWWROOT:-}" && -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]]; then
    export MOODLE_WWWROOT="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
if [[ -z "${MOODLE_WWWROOT:-}" && -n "${RAILWAY_STATIC_URL:-}" ]]; then
    export MOODLE_WWWROOT="https://${RAILWAY_STATIC_URL}"
fi
: "${MOODLE_WWWROOT:=http://localhost}"

: "${MOODLE_SITE_FULLNAME:=Moodle Site}"
: "${MOODLE_SITE_SHORTNAME:=Moodle}"
: "${MOODLE_ADMIN_USER:=admin}"
: "${MOODLE_ADMIN_PASS:=ChangeMeNow!123}"
: "${MOODLE_ADMIN_EMAIL:=admin@example.com}"
: "${MOODLE_LANG:=en}"

mkdir -p "${MOODLEDATA_DIR}"
chown -R www-data:www-data "${MOODLEDATA_DIR}"

if [[ ! -f "${MOODLE_DIR}/config.php" ]]; then
    php <<'PHP'
<?php
$configfile = '/var/www/html/config.php';

$cfg = [
    'dbtype' => getenv('MOODLE_DB_TYPE') ?: 'mariadb',
    'dbhost' => getenv('MOODLE_DB_HOST') ?: '',
    'dbport' => getenv('MOODLE_DB_PORT') ?: '3306',
    'dbname' => getenv('MOODLE_DB_NAME') ?: '',
    'dbuser' => getenv('MOODLE_DB_USER') ?: '',
    'dbpass' => getenv('MOODLE_DB_PASS') ?: '',
    'prefix' => getenv('MOODLE_DB_PREFIX') ?: 'mdl_',
    'wwwroot' => getenv('MOODLE_WWWROOT') ?: 'http://localhost',
    'dataroot' => getenv('MOODLE_DATA_ROOT') ?: '/var/moodledata',
    'admin' => getenv('MOODLE_ADMIN_PATH') ?: 'admin',
];

$boolenv = static function(string $name, bool $default): bool {
    $raw = getenv($name);
    if ($raw === false || $raw === '') {
        return $default;
    }
    $parsed = filter_var($raw, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    return $parsed ?? $default;
};

$sslproxy = $boolenv('MOODLE_SSLPROXY', true);
$reverseproxy = $boolenv('MOODLE_REVERSEPROXY', false);

$lines = [];
$lines[] = '<?php  // Moodle configuration file';
$lines[] = '';
$lines[] = 'unset($CFG);';
$lines[] = 'global $CFG;';
$lines[] = '$CFG = new stdClass();';
$lines[] = '';
$lines[] = '$CFG->dbtype    = ' . var_export($cfg['dbtype'], true) . ';';
$lines[] = '$CFG->dblibrary = \'native\';';
$lines[] = '$CFG->dbhost    = ' . var_export($cfg['dbhost'], true) . ';';
$lines[] = '$CFG->dbport    = ' . var_export($cfg['dbport'], true) . ';';
$lines[] = '$CFG->dbname    = ' . var_export($cfg['dbname'], true) . ';';
$lines[] = '$CFG->dbuser    = ' . var_export($cfg['dbuser'], true) . ';';
$lines[] = '$CFG->dbpass    = ' . var_export($cfg['dbpass'], true) . ';';
$lines[] = '$CFG->prefix    = ' . var_export($cfg['prefix'], true) . ';';
$lines[] = '$CFG->dboptions = array (';
$lines[] = '  \'dbpersist\' => 0,';
$lines[] = '  \'dbport\' => \'\',';
$lines[] = '  \'dbsocket\' => \'\',';
$lines[] = '  \'dbcollation\' => \'utf8mb4_unicode_ci\',';
$lines[] = ');';
$lines[] = '';
$lines[] = '$CFG->wwwroot   = ' . var_export($cfg['wwwroot'], true) . ';';
$lines[] = '$CFG->dataroot  = ' . var_export($cfg['dataroot'], true) . ';';
$lines[] = '$CFG->admin     = ' . var_export($cfg['admin'], true) . ';';
if ($sslproxy) {
    $lines[] = '$CFG->sslproxy = true;';
}
if ($reverseproxy) {
    $lines[] = '$CFG->reverseproxy = true;';
}
$lines[] = '';
$lines[] = '$CFG->directorypermissions = 02777;';
$lines[] = '';
$lines[] = 'require_once(__DIR__ . \'/lib/setup.php\');';
$lines[] = '';
$lines[] = '// There is no php closing tag in this file,';
$lines[] = '// it is intentional because it prevents trailing whitespace problems!';

file_put_contents($configfile, implode(PHP_EOL, $lines) . PHP_EOL);
PHP
fi

if [[ "${MOODLE_AUTO_INSTALL:-false}" == "true" ]]; then
    if php "${MOODLE_DIR}/admin/cli/isinstalled.php" >/dev/null 2>&1; then
        echo "Moodle is already installed. Skipping auto-install."
    elif [[ -z "${MOODLE_DB_HOST}" || -z "${MOODLE_DB_NAME}" || -z "${MOODLE_DB_USER}" || -z "${MOODLE_DB_PASS}" ]]; then
        echo "MOODLE_AUTO_INSTALL=true but DB env vars are missing. Starting web server without auto-install."
    else
        php "${MOODLE_DIR}/admin/cli/install.php" \
            --non-interactive \
            --agree-license \
            --lang="${MOODLE_LANG}" \
            --wwwroot="${MOODLE_WWWROOT}" \
            --dataroot="${MOODLEDATA_DIR}" \
            --dbtype="${MOODLE_DB_TYPE}" \
            --dbhost="${MOODLE_DB_HOST}" \
            --dbport="${MOODLE_DB_PORT}" \
            --dbname="${MOODLE_DB_NAME}" \
            --dbuser="${MOODLE_DB_USER}" \
            --dbpass="${MOODLE_DB_PASS}" \
            --fullname="${MOODLE_SITE_FULLNAME}" \
            --shortname="${MOODLE_SITE_SHORTNAME}" \
            --adminuser="${MOODLE_ADMIN_USER}" \
            --adminpass="${MOODLE_ADMIN_PASS}" \
            --adminemail="${MOODLE_ADMIN_EMAIL}"
    fi
fi

exec "$@"
