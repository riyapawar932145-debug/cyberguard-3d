"""One-time DB setup/seed script - creates tables from the models and inserts the 50 scenarios
from seed_scenarios.json. Works against whatever SQLALCHEMY_DATABASE_URI is configured (SQLite
in production on PythonAnywhere's free tier, MySQL locally) since it goes through the ORM
rather than raw SQL. Safe to re-run: skips any scenario code that's already in the table
instead of erroring or duplicating it.

Run from the backend/ directory with the virtualenv active:
    python seed_db.py
"""
import json

from app import create_app
from config import Config
from models import Scenario, db


def main() -> None:
    app = create_app(Config)
    with app.app_context():
        db.create_all()

        with open("seed_scenarios.json", encoding="utf-8") as f:
            scenarios = json.load(f)

        existing_codes = {code for (code,) in db.session.query(Scenario.code).all()}
        added = 0
        for s in scenarios:
            if s["code"] in existing_codes:
                continue
            db.session.add(
                Scenario(
                    code=s["code"],
                    room=s["room"],
                    title=s["title"],
                    difficulty=s["difficulty"],
                    is_fraud=s["is_fraud"],
                    red_flags=s["red_flags"],
                    correct_actions=s["correct_actions"],
                    content=json.dumps(s["content"], ensure_ascii=False),
                )
            )
            added += 1

        db.session.commit()
        print(f"Added {added} new scenarios ({len(existing_codes)} already present).")
        print("Total scenarios in DB:", db.session.query(Scenario).count())


if __name__ == "__main__":
    main()
