from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import os
import time
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]
)

app = Flask(__name__)
CORS(app)

DB_PATH = "/app/data/todo.db"

def ensure_db_exists():
    """Create the /app/data folder, the SQLite database file, and the tasks table if they don't exist."""
    try:
        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL
            )
        ''')
        conn.commit()
        conn.close()
        logging.info("Database directory, file, and table ensured.")
    except Exception as e:
        logging.error(f"SQLite DB initialization failed: {e}")

def get_connection():
    """Get a new SQLite connection."""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        logging.error(f"Failed to connect to SQLite: {e}")
        raise

@app.route("/api/healthcheck", methods=["GET"])
def healthcheck():
    """Healthcheck endpoint that reports SQLite status."""
    try:
        conn = get_connection()
        conn.execute("SELECT 1")
        conn.close()
        return jsonify({"status": "healthy", "db_connected": True}), 200
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "db_connected": False,
            "error": str(e)
        }), 503

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM tasks")
        tasks = [dict(row) for row in cursor.fetchall()]
        logging.info(f"Fetched {len(tasks)} tasks.")
        conn.close()
        return jsonify(tasks)
    except sqlite3.Error as e:
        logging.exception("Error fetching tasks")
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.json
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO tasks (title) VALUES (?)", (data["title"],))
        conn.commit()
        logging.info(f"Task added with title: {data['title']}")
        conn.close()
        return jsonify({"message": "Task added"}), 201
    except sqlite3.Error as e:
        logging.exception("Error adding task")
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
        conn.commit()
        logging.info(f"Task with ID {task_id} deleted.")
        conn.close()
        return jsonify({"message": "Task deleted"})
    except sqlite3.Error as e:
        logging.exception("Error deleting task")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    logging.info("Bootstrapping SQLite DB...")
    ensure_db_exists()

    logging.info("Starting Flask server...")
    app.run(host="0.0.0.0", port=5000)
