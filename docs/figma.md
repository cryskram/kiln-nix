# Figma desktop sign-in

The figma-linux Electron app ([0.11.5](https://github.com/Figma-Linux/figma-linux),
last release 2024-10) cannot complete a sign-in on its own against current
Figma. `figma-session-import` copies a working session out of Chrome instead.

## Symptom

"Login with browser" → browser login succeeds → "Open the desktop app" → back in
the app a spinner runs and the login page returns. Forever.

## Root cause

Both halves are verified locally, not inferred:

1. **The redeem writes an incomplete session.** The browser handoff lands
   `figma://app_auth/redeem?g_secret=…`, and the app stores a `figma.session`
   cookie — but not the `__Host-figma.authn`, `__Host-figma.authn-state` or
   `__Host-figma.authn.mac` cookies that current Figma also requires. Sending
   that cookie to the server bounces instead of authenticating:

   ```
   GET https://www.figma.com/files/recent   (cookie from the app's jar)
   → 200, final URL https://www.figma.com/login?is_not_gen_0=true
   ```

2. **The app cannot tell an unusable cookie from a valid one.** Its readiness
   check is name-existence only, so it logs `[wm] already signed in? true`,
   loads the workspace, gets rejected, and shows the login page again. That loop
   is the whole bug.

Separately, every `figma://` deep link starts a *new* process that crashes
before it can redeem:

```
TypeError: Cannot read properties of undefined (reading 'focus')
  at focusLastWindow … at new menuManager
```

`xdg-mime default figma-linux.desktop x-scheme-handler/figma` (set in
`home/applications.nix`) is already correct, so the handoff reaches the app —
it just cannot complete. Upstream is dormant, so this does not get fixed.

## The fix

```bash
figma-session-import              # import Chrome's session
figma-session-import --dry-run    # decrypt and report, change nothing
figma-session-import --kill       # stop a running app first (required if open)
```

Chrome must be signed in to figma.com (it holds the complete, valid cookie set),
and gnome-keyring must hold Chrome's `Chrome Safe Storage` secret. The script:

1. refuses to run while figma-linux is open (unless `--kill`), because the
   cookie DB is only safe to rewrite with the app stopped;
2. backs up `~/.config/figma-linux/Cookies` to `Cookies.bak-<timestamp>`;
3. reads Chrome's keyring secret and decrypts its figma cookies
   (PBKDF2-SHA1/`saltysalt` → AES-128-CBC, `v10`, stripping the 32-byte
   host-hash prefix that Chrome added in v127);
4. replaces the app's figma cookies with those rows, written as plaintext
   `value` with empty `encrypted_value` — the format this Electron build
   already uses for its own cookies.

Cookie values never leave the script and are never printed.

## When it breaks again

The session expires (~40 days for `figma.session`) and the login page returns.
Chrome will have refreshed its own cookies by then, so re-run
`figma-session-import`. Do not click through "Login with browser" expecting a
different result — it is the broken path.

Backups accumulate under `~/.config/figma-linux/Cookies.bak-*`; they are safe to
delete once sign-in works.

## Reinstalling does not help

`nixos-rebuild` produces the byte-identical store path, so there is no install
state to repair. Wiping `~/.config/figma-linux` gives a *fresh* profile that
still cannot complete the browser handoff — the import script is what makes it
work.

## Alternative

figma.com in Chrome works with no assistance (the desktop app only adds local
font access and plugin support). If the import becomes tiresome, install it as
a Chrome PWA instead. figma-linux stays packaged either way; the PWA is a
separate choice, not a fix.
