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

last_db_error = {"message": "Not yet attempted"}

def ensure_db_and_user_exist():
    """Ensure that the target database and user exist, and grant necessary permissions."""
    try:
        conn = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "mysql"),
            user="root",
            password=os.getenv("MYSQL_ROOT_PASSWORD", "root")
        )
        cursor = conn.cursor()

        db_name = os.getenv("MYSQL_DATABASE", "todo_db")
        db_user = os.getenv("MYSQL_USER", "root")
        db_pass = os.getenv("MYSQL_PASSWORD", "root")

        logging.info(f"Ensuring database '{db_name}' exists...")
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}`;")

        if db_user != "root":
            logging.info(f"Ensuring user '{db_user}' exists...")
            cursor.execute(f"CREATE USER IF NOT EXISTS '{db_user}'@'%' IDENTIFIED BY %s;", (db_pass,))
            cursor.execute(f"GRANT ALL PRIVILEGES ON `{db_name}`.* TO '{db_user}'@'%';")
            cursor.execute("FLUSH PRIVILEGES;")

        conn.commit()
        cursor.close()
        conn.close()
        logging.info("Database and user setup complete.")

    except Error as e:
        logging.error(f"Error ensuring DB/user exist: {e}")

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
    try:
        conn = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "mysql"),
            user=os.getenv("MYSQL_USER", "root"),
            password=os.getenv("MYSQL_PASSWORD", "root"),
            database=os.getenv("MYSQL_DATABASE", "todo_db")
        )
        if conn.is_connected():
            conn.close()
            return jsonify({"status": "healthy", "db_connected": True}), 200
        else:
            return jsonify({
                "status": "unhealthy",
                "db_connected": False,
                "error": "Connection object created but not connected"
            }), 503
    except Error as e:
        return jsonify({
            "status": "unhealthy",
            "db_connected": False,
            "error": str(e)
        }), 503

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
    logging.info("Bootstrapping DB and user...")
    ensure_db_and_user_exist()

    logging.info("Starting Flask server...")
    app.run(host="0.0.0.0", port=5000)
