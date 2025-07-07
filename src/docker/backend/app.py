from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import os
import shutil
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]
)

app = Flask(__name__)
CORS(app)

LOCAL_DB_PATH = "/todo.db"
BACKUP_DB_PATH = "/app/data/todo.db"

def backup_database():
    """Copy the working local DB to the backup location."""
    try:
        shutil.copy2(LOCAL_DB_PATH, BACKUP_DB_PATH)
        logging.info("Database backed up to Azure share.")
    except Exception as e:
        logging.error(f"Failed to backup DB: {e}")

def ensure_db_exists():
    """Ensure /todo.db exists. If backup exists, copy from it."""
    try:
        os.makedirs(os.path.dirname(BACKUP_DB_PATH), exist_ok=True)

        if not os.path.exists(LOCAL_DB_PATH) and os.path.exists(BACKUP_DB_PATH):
            shutil.copy2(BACKUP_DB_PATH, LOCAL_DB_PATH)
            logging.info("Restored DB from Azure share to local.")

        conn = sqlite3.connect(LOCAL_DB_PATH)
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL
            )
        ''')
        conn.commit()
        conn.close()
        logging.info("Local database and table ensured.")
        backup_database()
    except Exception as e:
        logging.error(f"SQLite DB initialization failed: {e}")

def get_connection():
    """Get a new SQLite connection."""
    try:
        conn = sqlite3.connect(LOCAL_DB_PATH)
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
        conn.close()
        logging.info(f"Fetched {len(tasks)} tasks.")
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
        conn.close()
        logging.info(f"Task added with title: {data['title']}")
        backup_database()
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
        conn.close()
        logging.info(f"Task with ID {task_id} deleted.")
        backup_database()
        return jsonify({"message": "Task deleted"})
    except sqlite3.Error as e:
        logging.exception("Error deleting task")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    logging.info("Bootstrapping SQLite DB...")
    ensure_db_exists()

    logging.info("Starting Flask server...")
    app.run(host="0.0.0.0", port=5000)
