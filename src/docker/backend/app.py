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
                user=os.getenv("MYSQL_ROOT_USER", "root"),
                password=os.getenv("MYSQL_ROOT_PASSWORD", "root"),
            )
            print("✅ Successfully connected to MySQL")
            conn.close()
            break
        except Error:
            print("❌ MySQL not ready. Retrying in 2 seconds...")
            time.sleep(2)

def create_app_user():
    try:
        conn = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "mysql"),
            user=os.getenv("MYSQL_ROOT_USER", "root"),
            password=os.getenv("MYSQL_ROOT_PASSWORD", "root"),
        )
        cursor = conn.cursor()

        app_user = os.getenv("MYSQL_USER", "hallo")
        app_pass = os.getenv("MYSQL_PASSWORD", "hallo")
        app_db = os.getenv("MYSQL_DATABASE", "todo_db")

        cursor.execute(f"""
            CREATE USER IF NOT EXISTS '{app_user}'@'%' IDENTIFIED BY '{app_pass}';
        """)
        cursor.execute(f"""
            GRANT ALL PRIVILEGES ON {app_db}.* TO '{app_user}'@'%';
        """)
        cursor.execute("FLUSH PRIVILEGES")

        conn.commit()
        cursor.close()
        conn.close()
        print(f"✅ MySQL user '{app_user}' created and granted access to '{app_db}'")
    except Error as e:
        print(f"❌ Failed to create MySQL user: {e}")

def get_connection():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "mysql"),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", "root"),
        database=os.getenv("MYSQL_DATABASE", "todo_db")
    )

@app.route("/api/tasks", methods=["GET"])
def get_tasks():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM tasks")
    tasks = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(tasks)

@app.route("/api/tasks", methods=["POST"])
def add_task():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO tasks (title) VALUES (%s)", (data["title"],))
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Task added"}), 201

@app.route("/api/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "Task deleted"})

if __name__ == "__main__":
    wait_for_db()
    create_app_user()
    app.run(host="0.0.0.0", port=5000)
