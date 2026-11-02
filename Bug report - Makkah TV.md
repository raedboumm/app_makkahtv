# Makkah TV — Problems Found and What Was Done

This report covers both the **mobile app** (phone app) and the **website**.
It is split into three parts:

1. Problems that were **fixed**
2. Problems that are **not fixed yet** and need a decision from you
3. **Small issues** worth fixing later

> Note: the fixes have been checked for mistakes in the code, but they have **not yet been tried on a real phone or in a browser**. Please test them before publishing.

---

## Part 1 — Problems that were fixed

### Mobile app

**1. The home screen video got "stuck" after using the small floating window**
- **The problem:** If you shrank the live video on the home screen into the small floating window (picture-in-picture) and then went back to the app, the video stayed on screen without any buttons. You couldn't pause it or do anything with it.
- **Why it happened:** The home screen and the live tab were both trying to listen for the same "floating window opened/closed" signal, and only one of them could hear it.
- **How it was fixed:** Both screens now share the same signal, and only the screen that opened the floating window reacts when it closes.

**2. Two live streams played at the same time**
- **The problem:** The live stream starts automatically on the home screen. If you then opened the "Live" tab, a second copy of the same stream started too, so you heard the sound twice and used double the internet data. A YouTube video playing on the home screen also kept playing after you moved to another tab.
- **How it was fixed:** The home screen now pauses its video when you leave it and picks up again when you come back. The "Live" tab also no longer starts playing by itself if you have already moved away while it was loading.

**3. The phone's "Back" button did nothing**
- **The problem:** On Android, pressing Back on the main screens did nothing. You couldn't go back to the home tab or close the app this way.
- **How it was fixed:** Back now takes you to the home tab, and pressing Back on the home tab closes the app, the way people expect.

**4. The app re-downloaded the whole video list every time it opened**
- **The problem:** The app is supposed to remember the channel's video list for 3 hours. But it was deleting that saved list every time it started, so it downloaded the full list of about 1,200 videos again on each launch. This makes the library slower and uses up the daily YouTube allowance much faster.
- **How it was fixed:** The app no longer deletes its saved list on startup. Also, if the download stops halfway (for example on a weak connection), the half list is no longer saved as if it were the full one.

**5. The app was much bigger than it needs to be**
- **The problem:** Some design files that the app never uses were being packed into it. One of them alone (`website.zip`) is about 34 MB. This made the app much bigger to download and install.
- **How it was fixed:** The app now only includes the two logo images it actually uses. The design files are still in the project folder; they just aren't packed into the app anymore.

**6. Pressing "Stop" while the stream was loading showed an error**
- **The problem:** If you pressed the stop button while the live stream was still loading, the app showed "Could not load the stream", even though nothing had gone wrong.
- **How it was fixed:** Stopping during loading now stops quietly, with no false error.

**7. The "Try again" and "Refresh" buttons didn't actually try again**
- **The problem:** When the stream failed, pressing "Try again" (إعادة المحاولة) only took you back to the cover picture. You had to tap a second time to really start the stream. The refresh button on the Live tab did the same.
- **How it was fixed:** These buttons now restart the stream straight away.

**8. Possible crashes when closing the live player**
- **The problem:** The parts of the live player were being shut down in the wrong order, which can cause errors or crashes when leaving or refreshing the player.
- **How it was fixed:** They are now shut down in the correct order.

**9. The app stopped staying upright after full screen**
- **The problem:** The app is designed to stay upright (portrait). But after watching the live stream in full screen and coming back, the app could start rotating sideways.
- **How it was fixed:** After full screen, the live player now puts the app back upright.

### Website

**10. A program page could crash**
- **The problem:** Going from one program's page to a program that doesn't exist (for example, an old or mistyped link) could make the page crash instead of showing "Program not found".
- **How it was fixed:** The page now shows the "not found" message properly.

**11. Sections on the home page kept resetting themselves**
- **The problem:** The "Daily broadcast" and "Live meetings" slideshows on the home page kept reloading from the start whenever anything else on the page changed, such as view counts arriving or picking a video.
- **How it was fixed:** These sections now load once and keep their place.

**12. The "Live" page kept streaming after you left it**
- **The problem:** After watching the stream on the Live page and moving to another page, the video kept downloading in the background and wasting data. The page could also show errors while it was being displayed.
- **How it was fixed:** The video now stops completely when you leave the page, and the page is built in a way that no longer causes those errors.

**13. Playlists could show the wrong videos**
- **The problem:** In the program library, if you opened one playlist and quickly opened another, the second playlist could end up showing the videos of the first one.
- **How it was fixed:** Only the playlist you actually have open can fill the screen now.

---

## Part 2 — Not fixed yet (needs a decision from you)

**A. The app is not ready for the Play Store / App Store**
- The app still uses a temporary placeholder name ("com.example…") as its official ID. The stores will not accept that.
- It is also "signed" with a temporary test key instead of your own permanent key.
- When this changes, the YouTube key settings must be updated too, or the video lists will stop loading in the published app.
- **What's needed from you:** the final official app ID you want (for example `com.makkahtv.app`) and your own signing key.

**B. The website's contact form doesn't send anything**
- When someone fills in the "Contact us" form, it says "Message sent successfully", but **the message goes nowhere** and is lost.
- The email box also doesn't check that what's typed is a real email address.
- **What's needed from you:** where messages should go, for example your server or an email address.

**C. The website plays the live stream in the background on every page**
- Every visitor downloads the live stream in a hidden player on every page of the site, even pages like News or Contact where it is never shown. This wastes visitors' data and adds load on the streaming service.
- If the internet drops for a moment, the live stream doesn't come back by itself.
- **Suggestion:** only load the stream when it is actually shown on screen, and make it reconnect by itself after a network drop.

**D. Background listening may stop on Android**
- The "audio only" mode on the Live tab is meant to keep playing when the phone is locked or in another app. Android usually stops it after a while, because the app doesn't run the kind of background service Android requires for this.

---

## Part 3 — Small issues worth fixing later

**Website**
- **Prayer times can show the wrong day.** For visitors in a time zone where it is already a different date than in Makkah (for example in America in the evening), the prayer times shown are for the wrong day. Isha time also isn't adjusted during Ramadan.
- **Fake viewer number.** The Live page always shows "12,453 viewers right now". This number is not real.
- **Missing X (Twitter) icon.** The X icon in the top bar doesn't appear. The "Live" menu item also has no icon.
- **Unrelated article.** Opening an article link that doesn't exist shows an unrelated example article (about city planning, with stock photos and a made-up author) instead of a "not found" message.
- **Duplicate video.** On the home page, "دروس الحرم" plays the same video as "آيات الحج".
- **Broken pictures.** One picture link is badly written, and another uses an insecure link, so some browsers may not show it.
- **Old data kept for hours.** If the YouTube list ever comes back empty, the website keeps showing an empty list for 3 hours.

**Mobile app**
- **Two different web addresses.** Sharing the channel frequencies sometimes uses `makkahtv.tv` and sometimes `makkahtv.com`.
- **Recorded video instead of live.** The program called "البث المباشر" (Live broadcast) opens a recorded video, not the live stream.
- **Pictures that may disappear.** Some pictures in the daily schedule are borrowed from Bing image search. They can disappear at any time.
- **Programs from the server can't play.** Programs that come from the server never get their video link, so they can't be played. This doesn't affect the app today, because it uses its built-in program list.
- **Unneeded security setting.** The app allows unsecured connections even though it doesn't need them.
- **No automatic tests.** The app has no real automatic tests to catch problems before release.
- **Unused screens.** Some screens and code are left over and never used (an old news tab, side menu, etc.). They could be cleaned up.

---

## What to do next

1. **Test the fixes:**
   - Try the floating window on the home screen.
   - Switch between tabs and make sure only one stream plays.
   - Use the Back button.
   - Reopen the app and check the library loads quickly.
2. **Send the details for Part 2:** the app ID and signing key, and where contact messages should go.
3. **Decide which Part 3 items to fix next.**
