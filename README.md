# CyberGuard 3D

A first-person 3D cybersecurity-awareness simulation. The player walks through five
distinct rooms, each modeling a real-world cyber threat category (phishing, UPI/OTP
fraud, fake login pages, weak passwords, unsafe browsing). There are no multiple-choice
quiz questions anywhere — every interaction is a free-form in-world action (open an
email, approve a payment, type a password) with a rendered consequence, followed by a
debrief explaining the cues that gave the fraud away.

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

All 29 tests (happy path + at least one failure case per endpoint) should pass without
a MySQL server running.

### Set up the database

```powershell
mysql -u root -p < backend\schema.sql
```

This creates the `cyberguard3d` database, all four tables, and 15 seed scenarios (3 per
room, mixing fraudulent and legitimate cases). It drops and recreates the tables if they
already exist — **if you previously ran the schema.sql that lived at the repo root
before this build (it lacked the `preferred_language` and `correct_actions` columns and
only seeded 3 scenarios), re-run `backend\schema.sql` against your MySQL instance to
migrate to the current schema.** That file at the repo root is now superseded by
`backend/schema.sql` and can be deleted once you've migrated.

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

## Adaptive difficulty & badges

- After 3 consecutive correct answers in a room, that room starts preferring
  difficulty-2 scenarios from the pool already fetched from the API (no extra network
  call). One incorrect answer resets the streak.
- The first time a player reaches 5 correct results in a row within a room, the server
  awards a `<room>_expert` badge (e.g. `phishing_inbox_expert`), surfaced in-game as a
  non-blocking toast.

## Localization

All player-facing strings are looked up through the `Localization` autoload
(`game/scripts/autoload/localization.gd`), which ships English and Hindi. Add a language
by adding a new top-level key to the `_strings` dictionary with every existing key
translated — never hardcode UI text directly in a scene script.
