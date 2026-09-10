"""DB connection configuration, driven entirely by environment variables."""
import os
from urllib.parse import quote_plus


class Config:
    SECRET_KEY: str = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False

    MYSQL_HOST: str = os.environ.get("MYSQL_HOST", "localhost")
    MYSQL_PORT: str = os.environ.get("MYSQL_PORT", "3306")
    MYSQL_USER: str = os.environ.get("MYSQL_USER", "root")
    MYSQL_PASSWORD: str = os.environ.get("MYSQL_PASSWORD", "")
    MYSQL_DB: str = os.environ.get("MYSQL_DB", "cyberguard3d")

    # Username/password must be percent-encoded before going into a URL - an unescaped
    # "@", ":" or "/" in the password would otherwise be misread as part of the URL structure.
    SQLALCHEMY_DATABASE_URI: str = os.environ.get(
        "DATABASE_URL",
        f"mysql+pymysql://{quote_plus(MYSQL_USER)}:{quote_plus(MYSQL_PASSWORD)}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}",
    )


class TestConfig(Config):
    """In-memory SQLite so the test suite never needs a live MySQL instance."""

    TESTING: bool = True
    SQLALCHEMY_DATABASE_URI: str = "sqlite:///:memory:"
