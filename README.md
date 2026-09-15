# CyberGuard 3D

A first-person 3D cybersecurity-awareness simulation. The player walks through seven
distinct rooms, each teaching a real-world cyber threat category through its own genuinely
different interaction mechanic — never a multiple-choice quiz:

- **Phishing Inbox** — emails open inline; hover the sender or the in-body link to reveal
  their real address before deciding to Report/Delete/Ignore (or just click the link).
- **UPI/OTP Kiosk** — a live incoming-request card with a ticking countdown; type an OTP,
  Approve, or Decline under real time pressure.
- **Fake Login Corridor** — the address bar starts inert; zoom into the domain to inspect
  it before the judgment-call buttons (Flag as Suspicious / Looks Legitimate) appear.
- **Password Vault Lab** — a live strength meter and a "time to crack" countdown react to
  every keystroke as you type a password.
- **Safe Browsing Street** — the same layout renders every time (a big tempting button next
  to small subtle real controls), so the UI itself never hints whether it's a trap.
- **Rapid Fire** — a kiosk terminal starts a timed session cycling through several short
  SAFE/UNSAFE judgment calls in a row, scored as a set.
- **Vulnerability Hunt** — explore a small office scene with several hotspots at once
  (a sticky-note password, an unlocked workstation, ...) and flag the real vulnerabilities.

On top of the rooms: a Trust-Score-driven level/title system (Cyber Rookie through Cyber
Sentinel), a live score breakdown with speed and streak bonuses, streak-combo and level-up
toasts, cross-room achievements (Perfect Run, Speed Demon, Cyber Sentinel) alongside the
per-room `<room>_expert` badges, and **CyberSense** — a standalone rule-based tool where you
paste a suspicious message and get an instant LOW/MEDIUM/HIGH/CRITICAL risk analysis.

## Repository layout

```
cyberguard3d/
├── backend/            Flask REST API + MySQL schema + pytest suite
├── game/                Godot 4.x project (GDScript, 3D)
└── README.md
```

## Backend setup

**Requirements:** Python 3.11+ (tested against 3.13), MySQL 8.0 for production use
(the test suite runs against an in-memory SQLite DB and needs no live database).

```powershell
cd backend
python -m pip install -r requirements.txt
```

### Run the test suite

```powershell
python -m pytest tests\test_api.py -v
```

All 39 tests (happy path + at least one failure case per endpoint, plus scoring/achievement
coverage) should pass without a MySQL server running.

### Set up the database

```powershell
mysql -u root -p < backend\schema.sql
```

This creates the `cyberguard3d` database, all four tables, and 30 seed scenarios (3+ per
room across all 7 rooms, mixing fraudulent/vulnerable and legitimate/safe cases). It drops
and recreates the tables every time it's run — **re-run this any time `backend/schema.sql`
changes** (it has changed several times during development: column additions, new action
vocabularies, new rooms) to keep your local database in sync with the current backend code.
The very first version of this file lived at the repo root and is now long superseded; if
it's still there, it can be deleted.

### Run the API

By default the app connects to `mysql+pymysql://root:@localhost:3306/cyberguard3d`.
Override any of these with environment variables before starting the server:

```powershell
$env:MYSQL_HOST = "localhost"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = "your-password"
$env:MYSQL_DB = "cyberguard3d"
# or set DATABASE_URL directly to override the whole connection string
python app.py
```

The API listens on `http://127.0.0.1:5000`. See the endpoint table in the original
project spec for the full contract; every endpoint validates input and returns proper
status codes (400/401/404/409 as appropriate) with `{"error": "..."}` bodies on failure.

## Game setup

**Requirements:** Godot Engine 4.2+ (this project was authored by hand as text `.tscn`
files against the Godot 4.2 format — it has not been opened in the editor in this
environment, since Godot isn't installed here. Open `game/project.godot` in Godot and do
a quick pass through each scene before your first playtest, in case anything needs a
minor fix-up the editor will point out).

1. Start the Flask API (see above) — the game expects it at `http://127.0.0.1:5000`
   (change `BASE_URL` in `game/scripts/autoload/api_client.gd` if you deploy elsewhere).
2. Open `game/project.godot` in Godot 4.
3. Press Play. The game boots to the main menu → Register/Login → a room-select hub
   showing your trust score and per-room accuracy → walk into any room.

**Controls:** WASD to move, mouse to look, Space to jump, left-click to interact with an
object within 5 meters, Esc to release/recapture the mouse.

### Admin module

A separate, unauthenticated 2D scenario-management screen, launched with a command-line
flag rather than being reachable from the normal game menus:

```powershell
godot4 --path game -- --admin
```

**Known limitation, by design for this build phase:** the admin module has no
authentication of its own. Anyone who can launch the game binary with `--admin` can
create/edit/delete scenarios. This is called out here deliberately rather than silently
left out — see `admin.no_auth_notice` in the in-app banner too.

## Adaptive difficulty, scoring & achievements

- After 3 consecutive correct answers in a room, that room starts preferring
  difficulty-2 scenarios from the pool already fetched from the API (no extra network
  call). One incorrect answer resets the streak.
- Every correct answer scores base points (+10) plus a **speed bonus** (up to +5, decaying
  from an instant response out to 8 seconds) plus a **streak bonus** (+1 per consecutive
  correct answer in that room, capped at +5) — the debrief panel shows the full breakdown.
  Incorrect answers are a flat -5 with no bonuses.
- Trust Score maps to a **level/title** (Cyber Rookie → ... → Cyber Sentinel at 1600),
  shown in the HUD and hub, with a level-up toast when you cross a threshold.
- The first time a player reaches 5 correct results in a row within a room, the server
  awards a `<room>_expert` badge (e.g. `phishing_inbox_expert`). Cross-room achievements
  layer on top: **Perfect Run** (10 correct in a row, any room), **Speed Demon** (5 correct
  in a row all answered within 4 seconds), and **Cyber Sentinel** (reach the top level).
  All badges surface in-game as non-blocking toasts, queued if several fire at once.

## Localization

All player-facing strings are looked up through the `Localization` autoload
(`game/scripts/autoload/localization.gd`), which ships English and Hindi. Add a language
by adding a new top-level key to the `_strings` dictionary with every existing key
translated — never hardcode UI text directly in a scene script.
