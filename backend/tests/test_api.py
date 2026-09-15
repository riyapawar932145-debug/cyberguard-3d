import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

from app import create_app
from config import TestConfig
from models import Scenario, User, db


@pytest.fixture()
def app():
    application = create_app(TestConfig)
    yield application
    with application.app_context():
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def seeded(app):
    """Seed one scenario per room used across the tests."""
    with app.app_context():
        scenarios = [
            Scenario(
                code="phishing_inbox_01",
                room="phishing_inbox",
                title="Fake KYC Email",
                difficulty=1,
                is_fraud=True,
                red_flags="wrong domain, urgent tone",
                correct_actions="reported,deleted",
                content='{"sender_display": "Bank", "link_url": "http://fake.example"}',
            ),
            Scenario(
                code="phishing_inbox_02",
                room="phishing_inbox",
                title="Real Colleague Email",
                difficulty=1,
                is_fraud=False,
                red_flags="none",
                correct_actions="opened",
            ),
            Scenario(
                code="upi_otp_kiosk_01",
                room="upi_otp_kiosk",
                title="OTP Share Request",
                difficulty=1,
                is_fraud=True,
                red_flags="never share OTP",
                correct_actions="decline",
            ),
        ]
        db.session.add_all(scenarios)
        db.session.commit()
        return {s.code: s.id for s in scenarios}


def register(client, username="alice", email="alice@example.com", password="hunter22"):
    return client.post(
        "/api/register",
        json={"username": username, "email": email, "password": password},
    )


# ---------------------------------------------------------------- register


def test_register_happy_path(client):
    resp = register(client)
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["username"] == "alice"
    assert "id" in body


def test_register_duplicate_username_conflicts(client):
    register(client)
    resp = register(client, email="other@example.com")
    assert resp.status_code == 409
    assert "error" in resp.get_json()


def test_register_missing_fields_400(client):
    resp = client.post("/api/register", json={"username": "bob"})
    assert resp.status_code == 400


def test_register_invalid_email_400(client):
    resp = register(client, email="not-an-email")
    assert resp.status_code == 400


# ------------------------------------------------------------------ login


def test_login_happy_path(client):
    register(client)
    resp = client.post("/api/login", json={"username": "alice", "password": "hunter22"})
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["username"] == "alice"
    assert body["trust_score"] == 0
    assert body["preferred_language"] == "en"


def test_login_wrong_password_401(client):
    register(client)
    resp = client.post("/api/login", json={"username": "alice", "password": "wrongpass"})
    assert resp.status_code == 401


def test_login_unknown_user_401(client):
    resp = client.post("/api/login", json={"username": "ghost", "password": "whatever"})
    assert resp.status_code == 401


# -------------------------------------------------------------- scenarios


def test_get_scenarios_happy_path(client, seeded):
    resp = client.get("/api/scenarios/phishing_inbox")
    assert resp.status_code == 200
    items = resp.get_json()
    assert len(items) == 2
    for item in items:
        assert "correct_actions" not in item
        assert "red_flags" not in item
        assert "is_fraud" not in item

    fake_kyc = next(i for i in items if i["title"] == "Fake KYC Email")
    assert fake_kyc["content"] == {"sender_display": "Bank", "link_url": "http://fake.example"}


def test_get_scenarios_content_defaults_to_empty_dict_when_unset(client, seeded):
    resp = client.get("/api/scenarios/upi_otp_kiosk")
    items = resp.get_json()
    assert items[0]["content"] == {}


def test_get_scenarios_unknown_room_404(client):
    resp = client.get("/api/scenarios/not_a_room")
    assert resp.status_code == 404


# ------------------------------------------------------------------ result


def test_submit_result_correct(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["phishing_inbox_01"]

    resp = client.post(
        "/api/result",
        json={
            "user_id": user_id,
            "scenario_id": scenario_id,
            "action_taken": "reported",
            "response_time_ms": 2500,
        },
    )
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["was_correct"] is True
    # base 10 + speed bonus 5 (2500ms is within the fast-response window) + streak bonus 1 (first
    # correct answer in this room) = 16
    assert body["score_delta"] == 16
    assert body["new_trust_score"] == 16
    assert body["score_breakdown"] == {"base": 10, "speed_bonus": 5, "streak_bonus": 1, "total": 16}
    assert body["red_flags"] == "wrong domain, urgent tone"
    assert body["badges_awarded"] == []


def test_submit_result_incorrect(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["phishing_inbox_01"]

    resp = client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "opened"},
    )
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["was_correct"] is False
    assert body["score_delta"] == -5
    assert body["new_trust_score"] == 0  # clamped at zero, not negative
    assert body["score_breakdown"] == {"base": -5, "speed_bonus": 0, "streak_bonus": 0, "total": -5}


def test_submit_result_awards_badge_after_five_streak(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    last_body = None
    for _ in range(5):
        resp = client.post(
            "/api/result",
            json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
        )
        last_body = resp.get_json()

    assert "upi_otp_kiosk_expert" in last_body["badges_awarded"]


def test_score_breakdown_streak_bonus_grows_and_caps(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    streak_bonuses = []
    for _ in range(7):
        resp = client.post(
            "/api/result",
            json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
        )
        streak_bonuses.append(resp.get_json()["score_breakdown"]["streak_bonus"])

    assert streak_bonuses == [1, 2, 3, 4, 5, 5, 5]


def test_score_breakdown_incorrect_answer_resets_streak_bonus(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
    )
    client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "shared_otp"},
    )
    resp = client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
    )
    assert resp.get_json()["score_breakdown"]["streak_bonus"] == 1


def test_global_achievement_speed_demon(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    last_body = None
    for _ in range(5):
        resp = client.post(
            "/api/result",
            json={
                "user_id": user_id,
                "scenario_id": scenario_id,
                "action_taken": "decline",
                "response_time_ms": 1500,
            },
        )
        last_body = resp.get_json()

    assert "speed_demon" in last_body["badges_awarded"]


def test_global_achievement_perfect_run(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    last_body = None
    for _ in range(10):
        resp = client.post(
            "/api/result",
            json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
        )
        last_body = resp.get_json()

    assert "perfect_run" in last_body["badges_awarded"]


def test_global_achievement_cyber_sentinel(client, app, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    with app.app_context():
        user = db.session.get(User, user_id)
        user.trust_score = 1599
        db.session.commit()

    resp = client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": scenario_id, "action_taken": "decline"},
    )
    assert "cyber_sentinel" in resp.get_json()["badges_awarded"]


def test_global_achievements_only_awarded_once(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    scenario_id = seeded["upi_otp_kiosk_01"]

    all_badges = []
    for _ in range(10):
        resp = client.post(
            "/api/result",
            json={
                "user_id": user_id,
                "scenario_id": scenario_id,
                "action_taken": "decline",
                "response_time_ms": 1000,
            },
        )
        all_badges.extend(resp.get_json()["badges_awarded"])

    assert all_badges.count("speed_demon") == 1
    assert all_badges.count("perfect_run") == 1


def test_submit_result_unknown_user_404(client, seeded):
    resp = client.post(
        "/api/result",
        json={"user_id": 9999, "scenario_id": seeded["phishing_inbox_01"], "action_taken": "reported"},
    )
    assert resp.status_code == 404


def test_submit_result_missing_fields_400(client, seeded):
    resp = client.post("/api/result", json={"scenario_id": seeded["phishing_inbox_01"]})
    assert resp.status_code == 400


# -------------------------------------------------------------- leaderboard


def test_leaderboard_happy_path(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": seeded["phishing_inbox_01"], "action_taken": "reported"},
    )

    resp = client.get("/api/leaderboard")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body[0]["username"] == "alice"
    assert body[0]["trust_score"] == 11  # base 10 + streak bonus 1 (first correct answer)


def test_leaderboard_empty_ok(client):
    resp = client.get("/api/leaderboard")
    assert resp.status_code == 200
    assert resp.get_json() == []


# ---------------------------------------------------------------- progress


def test_progress_happy_path(client, seeded):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": seeded["phishing_inbox_01"], "action_taken": "reported"},
    )
    client.post(
        "/api/result",
        json={"user_id": user_id, "scenario_id": seeded["phishing_inbox_02"], "action_taken": "reported"},
    )

    resp = client.get(f"/api/user/{user_id}/progress")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["phishing_inbox"]["completed"] == 2
    assert body["phishing_inbox"]["correct"] == 1
    assert body["phishing_inbox"]["accuracy_pct"] == 50.0
    assert body["upi_otp_kiosk"]["completed"] == 0


def test_progress_unknown_user_404(client):
    resp = client.get("/api/user/9999/progress")
    assert resp.status_code == 404


# ---------------------------------------------------------------- language


def test_update_language_happy_path(client):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]

    resp = client.put(f"/api/user/{user_id}/language", json={"language_code": "hi"})
    assert resp.status_code == 200
    assert resp.get_json()["preferred_language"] == "hi"


def test_update_language_unknown_user_404(client):
    resp = client.put("/api/user/9999/language", json={"language_code": "hi"})
    assert resp.status_code == 404


def test_update_language_missing_code_400(client):
    user_resp = register(client)
    user_id = user_resp.get_json()["id"]
    resp = client.put(f"/api/user/{user_id}/language", json={})
    assert resp.status_code == 400


# ------------------------------------------------------------------- admin


def test_admin_list_scenarios(client, seeded):
    resp = client.get("/api/admin/scenarios")
    assert resp.status_code == 200
    body = resp.get_json()
    assert len(body) == 3
    assert "correct_actions" in body[0]
    assert "is_fraud" in body[0]


def test_admin_create_scenario_happy_path(client):
    resp = client.post(
        "/api/admin/scenarios",
        json={
            "code": "safe_browsing_street_01",
            "room": "safe_browsing_street",
            "title": "HTTP Only Shop",
            "difficulty": 1,
            "is_fraud": True,
            "red_flags": "no https",
            "correct_actions": "leave,check_certificate",
        },
    )
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["code"] == "safe_browsing_street_01"


def test_admin_create_scenario_accepts_content_as_object(client):
    resp = client.post(
        "/api/admin/scenarios",
        json={
            "code": "safe_browsing_street_02",
            "room": "safe_browsing_street",
            "title": "Amazon",
            "is_fraud": False,
            "correct_actions": "enter_site",
            "content": {"domain": "https://www.amazon.in"},
        },
    )
    assert resp.status_code == 201
    assert resp.get_json()["content"] == '{"domain": "https://www.amazon.in"}'

    public = client.get("/api/scenarios/safe_browsing_street").get_json()
    created = next(s for s in public if s["code"] == "safe_browsing_street_02")
    assert created["content"] == {"domain": "https://www.amazon.in"}


def test_admin_create_scenario_rejects_malformed_content_json_400(client):
    resp = client.post(
        "/api/admin/scenarios",
        json={
            "code": "safe_browsing_street_03",
            "room": "safe_browsing_street",
            "title": "Bad Content",
            "is_fraud": False,
            "correct_actions": "enter_site",
            "content": "{not valid json",
        },
    )
    assert resp.status_code == 400


def test_admin_create_scenario_duplicate_code_409(client, seeded):
    resp = client.post(
        "/api/admin/scenarios",
        json={
            "code": "phishing_inbox_01",
            "room": "phishing_inbox",
            "title": "Dup",
            "is_fraud": True,
            "correct_actions": "reported",
        },
    )
    assert resp.status_code == 409


def test_admin_create_scenario_missing_fields_400(client):
    resp = client.post("/api/admin/scenarios", json={"code": "x"})
    assert resp.status_code == 400


def test_admin_update_scenario_happy_path(client, seeded):
    scenario_id = seeded["phishing_inbox_01"]
    resp = client.put(f"/api/admin/scenarios/{scenario_id}", json={"title": "Updated Title"})
    assert resp.status_code == 200
    assert resp.get_json()["title"] == "Updated Title"


def test_admin_update_scenario_content(client, seeded):
    scenario_id = seeded["phishing_inbox_01"]
    resp = client.put(
        f"/api/admin/scenarios/{scenario_id}",
        json={"content": {"link_url": "http://updated.example"}},
    )
    assert resp.status_code == 200
    assert resp.get_json()["content"] == '{"link_url": "http://updated.example"}'


def test_admin_update_scenario_not_found_404(client):
    resp = client.put("/api/admin/scenarios/9999", json={"title": "x"})
    assert resp.status_code == 404


def test_admin_delete_scenario_happy_path(client, seeded):
    scenario_id = seeded["phishing_inbox_01"]
    resp = client.delete(f"/api/admin/scenarios/{scenario_id}")
    assert resp.status_code == 204

    resp2 = client.get("/api/admin/scenarios")
    codes = [s["code"] for s in resp2.get_json()]
    assert "phishing_inbox_01" not in codes


def test_admin_delete_scenario_not_found_404(client):
    resp = client.delete("/api/admin/scenarios/9999")
    assert resp.status_code == 404
