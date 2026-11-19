<?php
// Copy this file to config.php (same folder) and fill it in.
// config.php is a PHP file, so nobody can read it from the browser.
return [
    // Back office login
    'admin_email'    => 'admin@makkahtv.live',
    'admin_password' => 'change-me-to-a-strong-password',

    // Any long random text (signs the login sessions). Changing it logs everyone out.
    'token_secret'   => 'put-a-long-random-text-here',
];
