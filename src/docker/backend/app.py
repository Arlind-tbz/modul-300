from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
from flask_cors import CORS
import os
import time

app = Flask(__name__)
CORS(app)

def wait_for_db():
    while True:
        try:
            conn = mysql.connector.connect(
                host=os.getenv("MYSQL_HOST", "mysql"),
                user=os.getenv("MYSQL_USER", "root"),
                password=os.getenv("MYSQL_PASSWORD", "root"),
                database=os.getenv("MYSQL_DATABASE", "todo_db")
            )
            print("✅ Successfully connected to MySQL")
            return conn
        except Error:
            print("❌ MySQL not ready. Retrying in 2 seconds...")
            time.sleep(2)

db = wait_for_db()
cursor = db.cursor(dictionary=True)

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    cursor.execute("SELECT * FROM tasks")
    return jsonify(cursor.fetchall())

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.json
    cursor.execute("INSERT INTO tasks (title) VALUES (%s)", (data["title"],))
    db.commit()
    return jsonify({"message": "Task added"}), 201

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
    db.commit()
    return jsonify({"message": "Task deleted"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
