from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from flask_cors import CORS
import os
import time
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]
)

app = Flask(__name__)
CORS(app)

# Track last known MySQL connection error
last_db_error = {"message": "Not yet attempted"}

def get_connection(delay=2):
    """Attempt to connect to MySQL indefinitely, log errors, and update error state."""
    global last_db_error
    while True:
        try:
            logging.info("Attempting to connect to MySQL...")
            conn = mysql.connector.connect(
                host=os.getenv("MYSQL_HOST", "mysql"),
                user=os.getenv("MYSQL_USER", "root"),
                password=os.getenv("MYSQL_PASSWORD", "root"),
                database=os.getenv("MYSQL_DATABASE", "todo_db")
            )
            if conn.is_connected():
                logging.info("Connected to MySQL.")
                last_db_error = None
                return conn
        except Error as e:
            last_db_error = {"message": str(e)}
            logging.error(f"MySQL connection failed: {e}. Retrying in {delay} seconds...")
            time.sleep(delay)

@app.route("/api/healthcheck", methods=["GET"])
def healthcheck():
    """Healthcheck endpoint that reports MySQL status."""
    if last_db_error:
        return jsonify({
            "status": "unhealthy",
            "db_connected": False,
            "error": last_db_error["message"]
        }), 503
    return jsonify({
        "status": "healthy",
        "db_connected": True
    })

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM tasks")
        tasks = cursor.fetchall()
        logging.info(f"Fetched {len(tasks)} tasks.")
        cursor.close()
        conn.close()
        return jsonify(tasks)
    except Error as e:
        logging.exception("Error fetching tasks")
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.json
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO tasks (title) VALUES (%s)", (data["title"],))
        conn.commit()
        logging.info(f"Task added with title: {data['title']}")
        cursor.close()
        conn.close()
        return jsonify({"message": "Task added"}), 201
    except Error as e:
        logging.exception("Error adding task")
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        conn.commit()
        logging.info(f"Task with ID {task_id} deleted.")
        cursor.close()
        conn.close()
        return jsonify({"message": "Task deleted"})
    except Error as e:
        logging.exception("Error deleting task")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    logging.info("Starting Flask server...")
    app.run(host="0.0.0.0", port=5000)
