from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from flask_cors import CORS
import os
import time

app = Flask(__name__)
CORS(app)

def get_connection(retries=3, delay=2):
    for attempt in range(retries):
        try:
            return mysql.connector.connect(
                host=os.getenv("MYSQL_HOST", "mysql"),
                user=os.getenv("MYSQL_USER", "root"),
                password=os.getenv("MYSQL_PASSWORD", "root"),
                database=os.getenv("MYSQL_DATABASE", "todo_db")
            )
        except Error as e:
            if attempt < retries - 1:
                time.sleep(delay)
            else:
                raise e

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM tasks")
        tasks = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(tasks)
    except Error as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.json
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO tasks (title) VALUES (%s)", (data["title"],))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Task added"}), 201
    except Error as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Task deleted"})
    except Error as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
