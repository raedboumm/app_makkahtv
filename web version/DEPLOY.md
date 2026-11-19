# Upload to makkahtv.live (FileZilla only)

The back office is PHP, so it works on normal hosting with just FTP. Nothing needs to be started.

## Every time you update the site

1. On your computer: `npm run build`
2. In FileZilla, upload **everything inside `dist/`** into the server folder **`/html`**, and overwrite.
   - Don't delete the existing `.htaccess` in `/html`.
   - Never delete `/html/api/data/`. It holds the saved settings and messages.

## The links

- Website: https://makkahtv.live/
- Back office: **https://makkahtv.live/admin/**
- Check the API: https://makkahtv.live/api/index.php?action=ping. It should show `{"ok":true,...}`.

## Login

The email and password are in `public/api/config.php` (copied to `dist/api/config.php` on build).
Change them there, run `npm run build`, and upload `dist/api/config.php` again.

## Where the data is saved

`/html/api/data/db.php` on the server. It's created automatically on first use, holds the settings
and messages, and can't be opened from a browser. To back it up, download it with FileZilla.

## On your computer

`npm run dev` starts the website on http://localhost:5173 and the back office on
http://localhost:5173/admin/. This needs PHP installed, which you already have. Local test data is
saved in `.local-data/`, never in `dist/`.
