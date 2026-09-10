"""SQLAlchemy models mirroring schema.sql exactly."""
from datetime import datetime, timezone

from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    trust_score = db.Column(db.Integer, default=0, nullable=False)
    preferred_language = db.Column(db.String(10), default="en", nullable=False)
    created_at = db.Column(db.DateTime, default=utcnow, nullable=False)

    results = db.relationship("Result", backref="user", cascade="all, delete-orphan")
    badges = db.relationship("Badge", backref="user", cascade="all, delete-orphan")

    def to_public_dict(self) -> dict:
        return {
            "id": self.id,
            "username": self.username,
            "trust_score": self.trust_score,
            "preferred_language": self.preferred_language,
        }


class Scenario(db.Model):
    __tablename__ = "scenarios"

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False)
    room = db.Column(db.String(50), nullable=False)
    title = db.Column(db.String(150), nullable=False)
    difficulty = db.Column(db.Integer, default=1, nullable=False)
    is_fraud = db.Column(db.Boolean, nullable=False)
    red_flags = db.Column(db.Text)
    correct_actions = db.Column(db.String(100), nullable=False)

    def to_public_dict(self) -> dict:
        """Player-facing view - never leaks the answer key before a result is submitted."""
        return {
            "id": self.id,
            "code": self.code,
            "room": self.room,
            "title": self.title,
            "difficulty": self.difficulty,
        }

    def to_admin_dict(self) -> dict:
        return {
            "id": self.id,
            "code": self.code,
            "room": self.room,
            "title": self.title,
            "difficulty": self.difficulty,
            "is_fraud": bool(self.is_fraud),
            "red_flags": self.red_flags,
            "correct_actions": self.correct_actions,
        }


class Result(db.Model):
    __tablename__ = "results"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    scenario_id = db.Column(db.Integer, db.ForeignKey("scenarios.id"), nullable=False)
    action_taken = db.Column(db.String(30), nullable=False)
    was_correct = db.Column(db.Boolean, nullable=False)
    score_delta = db.Column(db.Integer, nullable=False)
    response_time_ms = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=utcnow, nullable=False)

    scenario = db.relationship("Scenario")


class Badge(db.Model):
    __tablename__ = "badges"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    badge_code = db.Column(db.String(50), nullable=False)
    awarded_at = db.Column(db.DateTime, default=utcnow, nullable=False)
