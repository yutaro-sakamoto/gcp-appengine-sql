import os
import logging

from flask import Flask, jsonify, request
import pg8000

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

_db_initialized = False


def get_db_connection():
    return pg8000.connect(
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        port=5432,
    )


def init_db():
    global _db_initialized
    if _db_initialized:
        return
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS visitors (
                id SERIAL PRIMARY KEY,
                ip_address VARCHAR(45),
                visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                user_agent TEXT
            )
        """)
        conn.commit()
        cursor.close()
        conn.close()
        _db_initialized = True
        app.logger.info("Database initialized")
    except Exception as e:
        app.logger.error(f"Database init failed: {e}")


@app.route("/")
def index():
    """Record visit and return recent visitors."""
    init_db()
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        ip = request.headers.get("X-Forwarded-For", request.remote_addr)
        ua = request.headers.get("User-Agent", "unknown")
        cursor.execute(
            "INSERT INTO visitors (ip_address, user_agent) VALUES (%s, %s)",
            (ip, ua),
        )
        conn.commit()

        cursor.execute(
            "SELECT id, ip_address, visited_at FROM visitors ORDER BY visited_at DESC LIMIT 10"
        )
        rows = cursor.fetchall()
        cursor.close()
        conn.close()

        visitors = [
            {"id": r[0], "ip": r[1], "visited_at": str(r[2])} for r in rows
        ]
        return jsonify({"status": "ok", "recent_visitors": visitors})

    except Exception as e:
        app.logger.error(f"Database error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/health")
def health():
    """Health check for App Engine liveness/readiness probes."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        conn.close()
        return jsonify({"status": "healthy"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
