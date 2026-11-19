<?php
/**
 * Makkah TV back office API (PHP, no database).
 *
 * Every call goes to /api/index.php?action=...
 *
 *  Public (website):
 *    GET  config                 live stream + YouTube settings
 *    GET  captcha                new CAPTCHA image + token for the contact form
 *    POST contact                save a "تواصل معنا" message (needs captchaToken + captchaAnswer)
 *
 *  Admin (header X-Auth-Token from login):
 *    POST login                  { email, password }
 *    GET  admin_config
 *    POST save_config&section=   section = live | library | playlists
 *    GET  messages
 *    POST mark_read&id=          { read: true|false }
 *    POST delete_message&id=
 *
 * Data is saved in api/data/db.php (JSON behind a PHP "exit" line, so the
 * file can never be downloaded from the browser).
 */

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('X-Robots-Tag: noindex');

// ------------------------------------------------------------------ settings

$cfgFile = __DIR__ . '/config.php';
$CFG = is_file($cfgFile) ? (require $cfgFile) : [];
if (!is_array($CFG)) $CFG = [];

define('ADMIN_EMAIL', strtolower(trim((string)($CFG['admin_email'] ?? ''))));
define('ADMIN_PASSWORD', (string)($CFG['admin_password'] ?? ''));
define('TOKEN_SECRET', ((string)($CFG['token_secret'] ?? '')) !== ''
    ? (string)$CFG['token_secret']
    : hash('sha256', 'makkah:' . ADMIN_EMAIL . ':' . ADMIN_PASSWORD));
define('DATA_DIR', rtrim((string)(getenv('MAKKAH_DATA_DIR') ?: ($CFG['data_dir'] ?? (__DIR__ . '/data'))), '/\\'));
define('DB_FILE', DATA_DIR . '/db.php');
define('DB_GUARD', "<?php http_response_code(404); exit; ?>\n");
define('TOKEN_TTL', 12 * 3600);

// ------------------------------------------------------------------ helpers

function out(int $status, $body): void
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function body(): array
{
    $raw = file_get_contents('php://input', false, null, 0, 50000) ?: '';
    if ($raw === '') return [];
    $data = json_decode($raw, true);
    if (!is_array($data)) out(400, ['error' => 'Invalid JSON']);
    return $data;
}

function str_field($v, int $max): string
{
    $s = trim((string)($v ?? ''));
    return function_exists('mb_substr') ? mb_substr($s, 0, $max) : substr($s, 0, $max);
}

function now_iso(): string
{
    return gmdate('Y-m-d\TH:i:s\Z');
}

function client_ip(): string
{
    // Site is behind Cloudflare: it passes the visitor's real IP here.
    return (string)($_SERVER['HTTP_CF_CONNECTING_IP'] ?? $_SERVER['REMOTE_ADDR'] ?? '');
}

function uuid(): string
{
    $b = random_bytes(16);
    $b[6] = chr((ord($b[6]) & 0x0f) | 0x40);
    $b[8] = chr((ord($b[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4));
}

// ------------------------------------------------------------------ storage

function db_default(): array
{
    return [
        'config' => [
            'live' => [
                'label' => 'البث المباشر',
                'streamUrl' => 'https://media2.streambrothers.com:1936/8122/8122/playlist.m3u8',
                'active' => true,
                'updatedAt' => null,
            ],
            'library' => [
                'label' => 'مكتبة البرامج',
                'apiKey' => '',
                'playlistId' => 'UUGJ2xTzBAM-uuxCShVDY88g',
                'active' => true,
                'updatedAt' => null,
            ],
            'playlists' => [
                'label' => 'قوائم التشغيل',
                'apiKey' => '',
                'channelId' => 'UCGJ2xTzBAM-uuxCShVDY88g',
                'active' => true,
                'updatedAt' => null,
            ],
        ],
        'messages' => [],
        'rate' => [],
    ];
}

function ensure_data_dir(): void
{
    if (!is_dir(DATA_DIR) && !@mkdir(DATA_DIR, 0775, true)) {
        out(500, ['error' => 'Cannot create data folder — check folder write permissions on the server (api/)']);
    }
    // Extra protection on Apache; the db file itself is also PHP-guarded.
    $ht = DATA_DIR . '/.htaccess';
    if (!is_file($ht)) @file_put_contents($ht, "Require all denied\n");
    $idx = DATA_DIR . '/index.html';
    if (!is_file($idx)) @file_put_contents($idx, '');
}

/**
 * Runs $fn(&$db) under an exclusive file lock. If $fn returns true the db is
 * written back. Returns whatever $fn put in $result.
 */
function db_tx(callable $fn)
{
    ensure_data_dir();
    $fh = @fopen(DB_FILE, 'c+');
    if (!$fh) out(500, ['error' => 'Cannot open data file — check write permissions on api/data/']);
    flock($fh, LOCK_EX);

    $raw = stream_get_contents($fh) ?: '';
    if (strpos($raw, DB_GUARD) === 0) $raw = substr($raw, strlen(DB_GUARD));
    $stored = json_decode($raw, true);
    $def = db_default();
    $db = [
        'config' => [
            'live' => array_merge($def['config']['live'], $stored['config']['live'] ?? []),
            'library' => array_merge($def['config']['library'], $stored['config']['library'] ?? []),
            'playlists' => array_merge($def['config']['playlists'], $stored['config']['playlists'] ?? []),
        ],
        'messages' => is_array($stored['messages'] ?? null) ? $stored['messages'] : [],
        'rate' => is_array($stored['rate'] ?? null) ? $stored['rate'] : [],
        'captcha_used' => is_array($stored['captcha_used'] ?? null) ? $stored['captcha_used'] : [],
    ];

    $result = null;
    $dirty = $fn($db, $result) || $raw === '';

    if ($dirty) {
        $json = json_encode($db, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        ftruncate($fh, 0);
        rewind($fh);
        fwrite($fh, DB_GUARD . $json);
        fflush($fh);
    }
    flock($fh, LOCK_UN);
    fclose($fh);
    return $result;
}

/** True when `key` was hit more than $max times in $window seconds. */
function rate_limited(array &$db, string $key, int $max, int $window): bool
{
    $now = time();
    foreach ($db['rate'] as $k => $hits) {
        $db['rate'][$k] = array_values(array_filter($hits, fn($t) => $now - $t < 3600));
        if (!$db['rate'][$k]) unset($db['rate'][$k]);
    }
    $hits = array_values(array_filter($db['rate'][$key] ?? [], fn($t) => $now - $t < $window));
    $hits[] = $now;
    $db['rate'][$key] = $hits;
    return count($hits) > $max;
}

// ------------------------------------------------------------------ captcha
//
// Stateless: the answer is never sent to the browser, only an HMAC of it
// inside a signed, 10-minute token. Each token works once (used nonces are
// remembered in the db). The image is an SVG drawn from jittered strokes,
// not <text>, so a bot can't just read the digits out of the markup.

define('CAPTCHA_TTL', 600);
define('CAPTCHA_LEN', 5);

/** Stroke "font" for digits 2-9 (0/1 left out: easy to confuse), 10x16 box. */
function captcha_glyphs(): array
{
    return [
        '2' => [[[0, 3], [2, 0], [8, 0], [10, 3], [10, 6], [0, 16], [10, 16]]],
        '3' => [[[0, 1], [3, 0], [8, 0], [10, 3], [9, 6], [5, 8], [9, 9], [10, 13], [8, 16], [3, 16], [0, 14]]],
        '4' => [[[8, 16], [8, 0], [0, 11], [10, 11]]],
        '5' => [[[10, 0], [1, 0], [0, 7], [6, 6], [10, 9], [10, 13], [7, 16], [2, 16], [0, 14]]],
        '6' => [[[9, 1], [5, 0], [1, 3], [0, 9], [1, 14], [4, 16], [8, 16], [10, 13], [9, 9], [5, 8], [1, 10]]],
        '7' => [[[0, 0], [10, 0], [3, 16]], [[3, 8], [9, 8]]],
        '8' => [[[5, 7], [1, 5], [1, 2], [4, 0], [7, 0], [9, 2], [9, 5], [5, 7], [1, 10], [1, 14], [4, 16], [7, 16], [10, 14], [10, 10], [5, 7]]],
        '9' => [[[9, 7], [5, 9], [1, 7], [0, 3], [3, 0], [7, 0], [10, 3], [10, 9], [8, 14], [4, 16], [1, 15]]],
    ];
}

function rnd(float $min, float $max): float
{
    return $min + (random_int(0, 10000) / 10000) * ($max - $min);
}

function captcha_svg(string $code): string
{
    $w = 190; $h = 60;
    $glyphs = captcha_glyphs();
    $colors = ['#33241b', '#6b4a2f', '#4a3222', '#7a5535'];
    $parts = [];

    // Background noise: curves + dots.
    for ($i = 0; $i < 7; $i++) {
        $parts[] = sprintf(
            '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#c9b49c" stroke-width="%.1f" fill="none" opacity="0.8"/>',
            rnd(0, 40), rnd(0, $h), rnd(40, 150), rnd(-20, $h + 20), rnd(150, $w), rnd(0, $h), rnd(1, 2.2)
        );
    }
    for ($i = 0; $i < 45; $i++) {
        $parts[] = sprintf('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#b89c7e" opacity="0.7"/>', rnd(0, $w), rnd(0, $h), rnd(0.6, 1.8));
    }

    // Digits.
    $len = strlen($code);
    for ($i = 0; $i < $len; $i++) {
        $scale = rnd(1.9, 2.2);
        $x = 22 + $i * 31 + rnd(-2, 2);
        $y = 13 + rnd(-2, 2);
        $rot = rnd(-22, 22);
        $color = $colors[random_int(0, count($colors) - 1)];
        foreach ($glyphs[$code[$i]] as $stroke) {
            $d = '';
            foreach ($stroke as $k => [$px, $py]) {
                $d .= sprintf('%s%.1f %.1f ', $k ? 'L' : 'M', $px + rnd(-0.7, 0.7), $py + rnd(-0.7, 0.7));
            }
            $parts[] = sprintf(
                '<path d="%s" transform="translate(%.1f %.1f) rotate(%.1f 5 8) scale(%.2f)" stroke="%s" stroke-width="%.2f" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
                trim($d), $x, $y, $rot, $scale, $color, rnd(1.3, 1.7)
            );
        }
    }

    // A couple of lines across the digits.
    for ($i = 0; $i < 2; $i++) {
        $parts[] = sprintf(
            '<path d="M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f" stroke="#6b4a2f" stroke-width="1.3" fill="none" opacity="0.55"/>',
            rnd(0, 20), rnd(15, 45), rnd(50, 90), rnd(0, $h), rnd(100, 140), rnd(0, $h), rnd(170, $w), rnd(15, 45)
        );
    }

    // Shuffle so digit order in the markup doesn't match the visual order.
    shuffle($parts);
    return sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><rect width="100%%" height="100%%" fill="#faf7f3"/>%s</svg>', $w, $h, $w, $h, implode('', $parts));
}

function captcha_new(): array
{
    $digits = '23456789';
    $code = '';
    for ($i = 0; $i < CAPTCHA_LEN; $i++) $code .= $digits[random_int(0, strlen($digits) - 1)];
    $nonce = bin2hex(random_bytes(12));
    $payload = b64url(json_encode([
        'n' => $nonce,
        'h' => hash_hmac('sha256', $code . '|' . $nonce, TOKEN_SECRET . '|captcha'),
        'e' => time() + CAPTCHA_TTL,
    ]));
    $token = $payload . '.' . b64url(hash_hmac('sha256', $payload, TOKEN_SECRET . '|captcha-sig', true));
    return ['token' => $token, 'image' => 'data:image/svg+xml;base64,' . base64_encode(captcha_svg($code))];
}

/** Returns an error message, or null when the answer is right. Burns the token. */
function captcha_check(array &$db, string $token, string $answer): ?string
{
    $parts = explode('.', $token);
    if (count($parts) !== 2) return 'رمز التحقق مطلوب';
    [$payload, $sig] = $parts;
    if (!hash_equals(b64url(hash_hmac('sha256', $payload, TOKEN_SECRET . '|captcha-sig', true)), $sig)) {
        return 'رمز التحقق غير صالح، اطلب رمزاً جديداً';
    }
    $data = json_decode(b64url_dec($payload), true);
    $now = time();
    if (!is_array($data) || ($data['e'] ?? 0) < $now) return 'انتهت صلاحية رمز التحقق، اطلب رمزاً جديداً';

    // Forget expired nonces, then refuse a token that was already used.
    $used = array_filter($db['captcha_used'] ?? [], fn($exp) => $exp >= $now);
    $nonce = (string)($data['n'] ?? '');
    if (isset($used[$nonce])) {
        $db['captcha_used'] = $used;
        return 'رمز التحقق مستخدم، اطلب رمزاً جديداً';
    }
    $used[$nonce] = (int)$data['e']; // one try per image, right or wrong
    $db['captcha_used'] = $used;

    // Accept Arabic-Indic digits too (٠-٩ / ۰-۹).
    $answer = strtr(trim($answer), [
        '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
        '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4', '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
    ]);
    $answer = preg_replace('/\s+/', '', $answer);
    $expected = hash_hmac('sha256', $answer . '|' . $nonce, TOKEN_SECRET . '|captcha');
    if (!hash_equals((string)($data['h'] ?? ''), $expected)) return 'رمز التحقق غير صحيح';
    return null;
}

// ------------------------------------------------------------------ auth

function b64url(string $s): string
{
    return rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
}

function b64url_dec(string $s): string
{
    return (string)base64_decode(strtr($s, '-_', '+/'));
}

function sign_token(string $email): string
{
    $payload = b64url(json_encode(['email' => $email, 'exp' => time() + TOKEN_TTL]));
    return $payload . '.' . b64url(hash_hmac('sha256', $payload, TOKEN_SECRET, true));
}

function verify_token(string $token): bool
{
    $parts = explode('.', $token);
    if (count($parts) !== 2) return false;
    [$payload, $sig] = $parts;
    $expected = b64url(hash_hmac('sha256', $payload, TOKEN_SECRET, true));
    if (!hash_equals($expected, $sig)) return false;
    $data = json_decode(b64url_dec($payload), true);
    return is_array($data) && ($data['exp'] ?? 0) > time();
}

function require_admin(): void
{
    $token = (string)($_SERVER['HTTP_X_AUTH_TOKEN'] ?? '');
    if (!verify_token($token)) out(401, ['error' => 'Unauthorized']);
}

// ------------------------------------------------------------------ routes

$action = (string)($_GET['action'] ?? '');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

const SECTION_FIELDS = [
    'live' => ['label', 'streamUrl', 'active'],
    'library' => ['label', 'apiKey', 'playlistId', 'active'],
    'playlists' => ['label', 'apiKey', 'channelId', 'active'],
];

switch ($action) {

    case 'config': {
        $cfg = db_tx(function (array &$db, &$result) {
            $result = $db['config'];
            return false;
        });
        $l = $cfg['live']; $lib = $cfg['library']; $pl = $cfg['playlists'];
        out(200, [
            'live' => ['label' => $l['label'], 'streamUrl' => $l['active'] ? $l['streamUrl'] : '', 'active' => (bool)$l['active']],
            'library' => ['label' => $lib['label'], 'apiKey' => $lib['active'] ? $lib['apiKey'] : '', 'playlistId' => $lib['playlistId'], 'active' => (bool)$lib['active']],
            'playlists' => ['label' => $pl['label'], 'apiKey' => $pl['active'] ? $pl['apiKey'] : '', 'channelId' => $pl['channelId'], 'active' => (bool)$pl['active']],
        ]);
    }

    case 'captcha':
        out(200, captcha_new());

    case 'contact': {
        if ($method !== 'POST') out(405, ['error' => 'Method not allowed']);
        $b = body();
        if (!empty($b['website'])) out(201, ['ok' => true]); // honeypot: bots only

        $msg = [
            'id' => uuid(),
            'name' => str_field($b['name'] ?? '', 120),
            'email' => str_field($b['email'] ?? '', 200),
            'phone' => str_field($b['phone'] ?? '', 40),
            'subject' => str_field($b['subject'] ?? '', 200),
            'message' => str_field($b['message'] ?? '', 5000),
            'read' => false,
            'createdAt' => now_iso(),
        ];
        if ($msg['name'] === '' || $msg['email'] === '' || $msg['message'] === '') {
            out(400, ['error' => 'الاسم والبريد الإلكتروني والرسالة مطلوبة']);
        }
        if (!filter_var($msg['email'], FILTER_VALIDATE_EMAIL)) {
            out(400, ['error' => 'البريد الإلكتروني غير صالح']);
        }
        $token = (string)($b['captchaToken'] ?? '');
        $answer = (string)($b['captchaAnswer'] ?? '');
        $error = db_tx(function (array &$db, &$result) use ($msg, $token, $answer) {
            if (rate_limited($db, 'contact:' . client_ip(), 5, 600)) {
                $result = [429, 'عدد كبير من الرسائل، حاول لاحقاً'];
                return true;
            }
            $captchaError = captcha_check($db, $token, $answer);
            if ($captchaError !== null) {
                $result = [400, $captchaError, 'captcha'];
                return true;
            }
            array_unshift($db['messages'], $msg);
            $result = null;
            return true;
        });
        if ($error) out($error[0], ['error' => $error[1], 'field' => $error[2] ?? null]);
        out(201, ['ok' => true]);
    }

    case 'login': {
        if ($method !== 'POST') out(405, ['error' => 'Method not allowed']);
        $b = body();
        $limited = db_tx(function (array &$db, &$result) {
            $result = rate_limited($db, 'login:' . client_ip(), 10, 900);
            return true;
        });
        if ($limited) out(429, ['error' => 'محاولات كثيرة، حاول بعد قليل']);

        $email = strtolower(trim((string)($b['email'] ?? '')));
        $pass = (string)($b['password'] ?? '');
        // Compare both every time so timing doesn't reveal which one was wrong.
        $emailOk = hash_equals(hash('sha256', ADMIN_EMAIL), hash('sha256', $email));
        $passOk = hash_equals(hash('sha256', ADMIN_PASSWORD), hash('sha256', $pass));
        if (ADMIN_EMAIL === '' || ADMIN_PASSWORD === '' || !$emailOk || !$passOk) {
            out(401, ['error' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة']);
        }
        out(200, ['token' => sign_token(ADMIN_EMAIL), 'email' => ADMIN_EMAIL]);
    }

    case 'admin_config': {
        require_admin();
        out(200, db_tx(function (array &$db, &$result) {
            $result = $db['config'];
            return false;
        }));
    }

    case 'save_config': {
        require_admin();
        if ($method !== 'POST') out(405, ['error' => 'Method not allowed']);
        $section = (string)($_GET['section'] ?? '');
        if (!isset(SECTION_FIELDS[$section])) out(400, ['error' => 'Unknown section']);
        $b = body();

        if ($section === 'live' && isset($b['streamUrl']) && trim((string)$b['streamUrl']) !== ''
            && !preg_match('#^https?://#i', trim((string)$b['streamUrl']))) {
            out(400, ['error' => 'رابط البث يجب أن يبدأ بـ http أو https']);
        }

        out(200, db_tx(function (array &$db, &$result) use ($section, $b) {
            $next = $db['config'][$section];
            foreach (SECTION_FIELDS[$section] as $f) {
                if (!array_key_exists($f, $b)) continue;
                $next[$f] = $f === 'active' ? (bool)$b[$f] : str_field($b[$f], 500);
            }
            $next['updatedAt'] = now_iso();
            $db['config'][$section] = $next;
            $result = $next;
            return true;
        }));
    }

    case 'messages': {
        require_admin();
        out(200, db_tx(function (array &$db, &$result) {
            $result = $db['messages'];
            return false;
        }));
    }

    case 'mark_read':
    case 'delete_message': {
        require_admin();
        if ($method !== 'POST') out(405, ['error' => 'Method not allowed']);
        $id = (string)($_GET['id'] ?? '');
        $b = $action === 'mark_read' ? body() : [];

        $res = db_tx(function (array &$db, &$result) use ($id, $action, $b) {
            foreach ($db['messages'] as $i => $m) {
                if (($m['id'] ?? '') !== $id) continue;
                if ($action === 'delete_message') {
                    array_splice($db['messages'], $i, 1);
                    $result = ['ok' => true];
                } else {
                    $db['messages'][$i]['read'] = (bool)($b['read'] ?? false);
                    $result = $db['messages'][$i];
                }
                return true;
            }
            $result = null;
            return false;
        });
        if ($res === null) out(404, ['error' => 'Not found']);
        out(200, $res);
    }

    case 'ping':
        out(200, ['ok' => true, 'php' => PHP_VERSION, 'loginConfigured' => ADMIN_EMAIL !== '' && ADMIN_PASSWORD !== '']);

    default:
        out(404, ['error' => 'Unknown action']);
}
