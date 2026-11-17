# figma-linux's browser login stores only figma.session, but Figma also needs __Host-figma.authn*; copy Chrome's set (docs/figma.md).
set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/figma-linux"
APP_DB="$CFG_DIR/Cookies"
CHROME_PROFILE="${CHROME_PROFILE:-$HOME/.config/google-chrome/Default}"
CHROME_DB="$CHROME_PROFILE/Cookies"
KILL=0
DRY=0

usage() {
  cat <<'EOF'
Usage: figma-session-import [--kill] [--dry-run] [--chrome-profile DIR]

Copies the figma.com cookies from Chrome into figma-linux's profile so the app
treats you as signed in. figma-linux must be closed (use --kill to stop it).

  --kill                 stop a running figma-linux first
  --dry-run              decrypt and report, change nothing
  --chrome-profile DIR   Chrome profile to read (default: ~/.config/google-chrome/Default)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kill) KILL=1 ;;
    --dry-run) DRY=1 ;;
    --chrome-profile)
      CHROME_PROFILE="${2:?--chrome-profile needs a directory}"
      CHROME_DB="$CHROME_PROFILE/Cookies"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

[[ -f "$APP_DB" ]] || {
  echo "error: figma-linux profile not found at $APP_DB" >&2
  exit 1
}
[[ -f "$CHROME_DB" ]] || {
  echo "error: Chrome cookie DB not found at $CHROME_DB" >&2
  exit 1
}

if pgrep -f "figma[-]linux/resources/app" >/dev/null; then
  if [[ $KILL -eq 1 ]]; then
    echo "stopping figma-linux..."
    pkill -f "figma[-]linux/resources/app" || true
    for _ in $(seq 1 20); do
      pgrep -f "figma[-]linux/resources/app" >/dev/null || break
      sleep 0.25
    done
    pgrep -f "figma[-]linux/resources/app" >/dev/null && {
      echo "error: figma-linux did not exit" >&2
      exit 1
    }
  else
    echo "error: figma-linux is running; close it or pass --kill" >&2
    exit 1
  fi
fi

CHROME_SECRET="$(secret-tool lookup application chrome 2>/dev/null || true)"
if [[ -z "$CHROME_SECRET" ]]; then
  cat >&2 <<'EOF'
error: could not read Chrome's "Chrome Safe Storage" secret from the keyring.

Chrome must have stored it in the running keyring (gnome-keyring here). If it
is missing, unlock the login keyring and try again. If Chrome uses the
XDG secret portal instead, this import route does not apply.
EOF
  exit 1
fi

if [[ $DRY -eq 0 ]]; then
  BACKUP="$APP_DB.bak-$(date +%Y%m%d-%H%M%S)"
  cp -p "$APP_DB" "$BACKUP"
  echo "backed up: $BACKUP"
fi

TMPDIR_IMPORT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_IMPORT"' EXIT
cp "$CHROME_DB" "$TMPDIR_IMPORT/Cookies"
[[ -f "$CHROME_DB-wal" ]] && cp "$CHROME_DB-wal" "$TMPDIR_IMPORT/Cookies-wal"
[[ -f "$CHROME_DB-shm" ]] && cp "$CHROME_DB-shm" "$TMPDIR_IMPORT/Cookies-shm"

CHROME_SECRET="$CHROME_SECRET" APP_DB="$APP_DB" CHROME_COPY="$TMPDIR_IMPORT/Cookies" DRY="$DRY" \
  python3 <<'PY'
import hashlib, os, sqlite3, subprocess, time

secret = os.environ["CHROME_SECRET"].encode()
app_db = os.environ["APP_DB"]
chrome_copy = os.environ["CHROME_COPY"]
dry = os.environ["DRY"] == "1"

key = hashlib.pbkdf2_hmac("sha1", secret, b"saltysalt", 1, 16)
iv = b" " * 16


def unseal(blob):
    if not blob:
        return None
    if blob[:3] not in (b"v10", b"v11"):
        return blob
    out = subprocess.run(
        ["openssl", "enc", "-d", "-aes-128-cbc", "-K", key.hex(), "-iv", iv.hex(), "-nopad"],
        input=blob[3:], capture_output=True,
    ).stdout
    if not out:
        return None
    pad = out[-1]
    if 1 <= pad <= 16:
        out = out[:-pad]
    return out


# Chrome >= 127 prefixes values with SHA256(host_key); try both forms and keep whichever decodes to printable text.
def to_text(raw):
    for cand in ([raw[32:], raw] if len(raw) > 32 else [raw]):
        try:
            text = cand.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if text and all(ch.isprintable() for ch in text):
            return text
    return None


src = sqlite3.connect(f"file:{chrome_copy}?mode=ro", uri=True)
rows = src.execute(
    """select host_key, name, encrypted_value, path, expires_utc,
              is_secure, is_httponly, samesite, is_persistent
         from cookies where host_key like '%figma%'"""
).fetchall()

cookies = []
for host, name, enc, path, exp, sec, http, ss, pers in rows:
    raw = unseal(enc)
    text = to_text(raw) if raw else None
    if text is None:
        print(f"  skip {name}: undecodable value")
        continue
    cookies.append((host, name, text, path or "/", exp or 0, bool(sec), bool(http),
                    ss if ss is not None else 1, bool(pers)))

if not cookies:
    raise SystemExit("error: no figma cookies found in Chrome")

session = next((c for c in cookies if c[1] == "figma.session"), None)
if session is None:
    raise SystemExit("error: Chrome has no figma.session cookie — sign in to figma.com in Chrome first")
print(f"  Chrome: {len(cookies)} figma cookies, figma.session {len(session[2])} bytes")

if dry:
    for host, name, text, *_ in sorted(cookies, key=lambda c: c[1]):
        print(f"    {name:26} {len(text):4} bytes  ({host})")
    raise SystemExit(0)

now = int(time.time() * 1_000_000) + 11_644_473_600_000_000
db = sqlite3.connect(app_db)
db.execute("delete from cookies where host_key like '%figma%'")
db.executemany(
    """insert into cookies (creation_utc, host_key, top_frame_site_key, name, value,
          encrypted_value, path, expires_utc, is_secure, is_httponly, last_access_utc,
          has_expires, is_persistent, priority, samesite, source_scheme, source_port,
          last_update_utc, source_type, has_cross_site_ancestor)
       values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
    [(now, host, "", name, text, b"", path, exp, int(sec), int(http), now,
      1 if pers or exp else 0, 1 if pers else 0, 1, ss, 2, 443, now, 0, 0)
     for host, name, text, path, exp, sec, http, ss, pers in cookies],
)
db.commit()
count = db.execute(
    "select count(*) from cookies where host_key like '%figma%'"
).fetchone()[0]
db.close()
print(f"  imported {count} cookies into figma-linux")
PY

echo
echo "done. start figma-linux; it should open your workspace directly."
[[ $DRY -eq 1 ]] && echo "(dry run: nothing was changed)"
