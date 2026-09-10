"""CyberGuard 3D Flask API - all route definitions."""
import re

from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.security import check_password_hash, generate_password_hash

from config import Config
from models import Badge, Result, Scenario, User, db

ROOMS = [
    "phishing_inbox",
    "upi_otp_kiosk",
    "fake_login_corridor",
    "password_vault_lab",
    "safe_browsing_street",
]

CORRECT_SCORE_DELTA = 10
INCORRECT_SCORE_DELTA = -5
STREAK_FOR_BADGE = 5

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def error(message: str, status: int):
    return jsonify({"error": message}), status


def check_and_award_badge(user: User, room: str):
    """Award '<room>_expert' the first time a user hits 5 correct results in a row in that room."""
    badge_code = f"{room}_expert"

    already_has = Badge.query.filter_by(user_id=user.id, badge_code=badge_code).first()
    if already_has:
        return None

    recent = (
        Result.query.join(Scenario, Result.scenario_id == Scenario.id)
        .filter(Result.user_id == user.id, Scenario.room == room)
        .order_by(Result.created_at.desc(), Result.id.desc())
        .limit(STREAK_FOR_BADGE)
        .all()
    )

    if len(recent) < STREAK_FOR_BADGE or not all(r.was_correct for r in recent):
        return None

    badge = Badge(user_id=user.id, badge_code=badge_code)
    db.session.add(badge)
    db.session.commit()
    return badge_code


def create_app(config_class=Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    CORS(app)

    if app.config.get("TESTING"):
        with app.app_context():
            db.create_all()

    register_routes(app)
    register_error_handlers(app)
    return app


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(404)
    def not_found(_e):
        return error("Not found", 404)

    @app.errorhandler(405)
    def method_not_allowed(_e):
        return error("Method not allowed", 405)

    @app.errorhandler(500)
    def internal_error(_e):
        db.session.rollback()
        return error("Internal server error", 500)


def register_routes(app: Flask) -> None:
    @app.route("/api/register", methods=["POST"])
    def register():
        body = request.get_json(silent=True) or {}
        username = (body.get("username") or "").strip()
        email = (body.get("email") or "").strip().lower()
        password = body.get("password") or ""

        if not username or not email or not password:
            return error("username, email and password are required", 400)
        if len(username) < 3 or len(username) > 50:
            return error("username must be 3-50 characters", 400)
        if not EMAIL_RE.match(email):
            return error("invalid email format", 400)
        if len(password) < 6:
            return error("password must be at least 6 characters", 400)

        if User.query.filter_by(username=username).first():
            return error("username already taken", 409)
        if User.query.filter_by(email=email).first():
            return error("email already registered", 409)

        user = User(
            username=username,
            email=email,
            password_hash=generate_password_hash(password),
        )
        db.session.add(user)
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return error("could not create account", 409)

        return jsonify({"id": user.id, "username": user.username}), 201

    @app.route("/api/login", methods=["POST"])
    def login():
        body = request.get_json(silent=True) or {}
        username = (body.get("username") or "").strip()
        password = body.get("password") or ""

        if not username or not password:
            return error("username and password are required", 400)

        user = User.query.filter_by(username=username).first()
        if not user or not check_password_hash(user.password_hash, password):
            return error("invalid username or password", 401)

        return jsonify(user.to_public_dict()), 200

    @app.route("/api/scenarios/<string:room>", methods=["GET"])
    def get_scenarios(room: str):
        if room not in ROOMS:
            return error(f"unknown room '{room}'", 404)

        scenarios = Scenario.query.filter_by(room=room).all()
        return jsonify([s.to_public_dict() for s in scenarios]), 200

    @app.route("/api/result", methods=["POST"])
    def submit_result():
        body = request.get_json(silent=True) or {}
        user_id = body.get("user_id")
        scenario_id = body.get("scenario_id")
        action_taken = (body.get("action_taken") or "").strip()
        response_time_ms = body.get("response_time_ms")

        if not user_id or not scenario_id or not action_taken:
            return error("user_id, scenario_id and action_taken are required", 400)

        user = db.session.get(User, user_id)
        if not user:
            return error("user not found", 404)

        scenario = db.session.get(Scenario, scenario_id)
        if not scenario:
            return error("scenario not found", 404)

        correct_actions = [a.strip() for a in scenario.correct_actions.split(",")]
        was_correct = action_taken in correct_actions
        score_delta = CORRECT_SCORE_DELTA if was_correct else INCORRECT_SCORE_DELTA
        user.trust_score = max(0, user.trust_score + score_delta)

        result = Result(
            user_id=user.id,
            scenario_id=scenario.id,
            action_taken=action_taken,
            was_correct=was_correct,
            score_delta=score_delta,
            response_time_ms=response_time_ms,
        )
        db.session.add(result)
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return error("could not save result", 400)

        badge_awarded = check_and_award_badge(user, scenario.room)

        return (
            jsonify(
                {
                    "was_correct": was_correct,
                    "score_delta": score_delta,
                    "new_trust_score": user.trust_score,
                    "red_flags": scenario.red_flags,
                    "badge_awarded": badge_awarded,
                }
            ),
            200,
        )

    @app.route("/api/leaderboard", methods=["GET"])
    def leaderboard():
        top_users = User.query.order_by(User.trust_score.desc()).limit(10).all()
        return (
            jsonify([{"username": u.username, "trust_score": u.trust_score} for u in top_users]),
            200,
        )

    @app.route("/api/user/<int:user_id>/progress", methods=["GET"])
    def progress(user_id: int):
        user = db.session.get(User, user_id)
        if not user:
            return error("user not found", 404)

        report = {}
        for room in ROOMS:
            room_results = (
                Result.query.join(Scenario, Result.scenario_id == Scenario.id)
                .filter(Result.user_id == user_id, Scenario.room == room)
                .all()
            )
            completed = len(room_results)
            correct = sum(1 for r in room_results if r.was_correct)
            accuracy_pct = round((correct / completed) * 100, 1) if completed else 0.0
            report[room] = {
                "completed": completed,
                "correct": correct,
                "accuracy_pct": accuracy_pct,
            }

        return jsonify(report), 200

    @app.route("/api/user/<int:user_id>/language", methods=["PUT"])
    def update_language(user_id: int):
        user = db.session.get(User, user_id)
        if not user:
            return error("user not found", 404)

        body = request.get_json(silent=True) or {}
        language_code = (body.get("language_code") or "").strip()
        if not language_code:
            return error("language_code is required", 400)
        if len(language_code) > 10:
            return error("language_code too long", 400)

        user.preferred_language = language_code
        db.session.commit()

        return jsonify({"preferred_language": user.preferred_language}), 200

    @app.route("/api/admin/scenarios", methods=["GET"])
    def admin_list_scenarios():
        scenarios = Scenario.query.order_by(Scenario.id).all()
        return jsonify([s.to_admin_dict() for s in scenarios]), 200

    @app.route("/api/admin/scenarios", methods=["POST"])
    def admin_create_scenario():
        body = request.get_json(silent=True) or {}
        code = (body.get("code") or "").strip()
        room = (body.get("room") or "").strip()
        title = (body.get("title") or "").strip()
        is_fraud = body.get("is_fraud")
        correct_actions = (body.get("correct_actions") or "").strip()
        difficulty = body.get("difficulty", 1)
        red_flags = body.get("red_flags", "")

        if not code or not room or not title or is_fraud is None or not correct_actions:
            return error(
                "code, room, title, is_fraud and correct_actions are required", 400
            )
        if room not in ROOMS:
            return error(f"unknown room '{room}'", 400)
        if not isinstance(is_fraud, bool):
            return error("is_fraud must be a boolean", 400)

        if Scenario.query.filter_by(code=code).first():
            return error("scenario code already exists", 409)

        scenario = Scenario(
            code=code,
            room=room,
            title=title,
            difficulty=difficulty,
            is_fraud=is_fraud,
            red_flags=red_flags,
            correct_actions=correct_actions,
        )
        db.session.add(scenario)
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return error("could not create scenario", 409)

        return jsonify(scenario.to_admin_dict()), 201

    @app.route("/api/admin/scenarios/<int:scenario_id>", methods=["PUT"])
    def admin_update_scenario(scenario_id: int):
        scenario = db.session.get(Scenario, scenario_id)
        if not scenario:
            return error("scenario not found", 404)

        body = request.get_json(silent=True) or {}
        if not body:
            return error("request body is required", 400)

        if "room" in body and body["room"] not in ROOMS:
            return error(f"unknown room '{body['room']}'", 400)
        if "is_fraud" in body and not isinstance(body["is_fraud"], bool):
            return error("is_fraud must be a boolean", 400)

        for field in ("code", "room", "title", "difficulty", "is_fraud", "red_flags", "correct_actions"):
            if field in body:
                setattr(scenario, field, body[field])

        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return error("could not update scenario", 409)

        return jsonify(scenario.to_admin_dict()), 200

    @app.route("/api/admin/scenarios/<int:scenario_id>", methods=["DELETE"])
    def admin_delete_scenario(scenario_id: int):
        scenario = db.session.get(Scenario, scenario_id)
        if not scenario:
            return error("scenario not found", 404)

        db.session.delete(scenario)
        db.session.commit()
        return "", 204


if __name__ == "__main__":
    flask_app = create_app()
    flask_app.run(host="0.0.0.0", port=5000, debug=True)

