from flask import Flask, render_template, request, redirect, url_for
import requests
import os
import time

app = Flask(__name__)
BACKEND_HOST = os.getenv("BACKEND_HOST", "backend")
BACKEND_API = f"http://{BACKEND_HOST}:5000/api"

def wait_for_backend(delay=2):
    """Keep checking /healthcheck until backend is ready."""
    health_url = f"{BACKEND_API}/healthcheck"
    while True:
        try:
            print(f"🔍 Checking backend health at {health_url}...")
            res = requests.get(health_url)
            if res.status_code == 200 and res.json().get("db_connected"):
                print("✅ Backend is healthy.")
                return
            else:
                print(f"❌ Backend unhealthy: {res.text}")
        except requests.RequestException as e:
            print(f"⚠️ Backend healthcheck failed: {e}")
        time.sleep(delay)

def get_with_retries(endpoint, delay=2):
    while True:
        try:
            res = requests.get(f"{BACKEND_API}{endpoint}")
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            print(f"⚠️ GET {endpoint} failed: {e}. Retrying...")
            time.sleep(delay)

def post_with_retries(endpoint, data, delay=2):
    while True:
        try:
            res = requests.post(f"{BACKEND_API}{endpoint}", json=data)
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            print(f"⚠️ POST {endpoint} failed: {e}. Retrying...")
            time.sleep(delay)

def delete_with_retries(endpoint, delay=2):
    while True:
        try:
            res = requests.delete(f"{BACKEND_API}{endpoint}")
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            print(f"⚠️ DELETE {endpoint} failed: {e}. Retrying...")
            time.sleep(delay)

@app.route("/", methods=["GET"])
def index():
    try:
        wait_for_backend()  # Wait for health before any request
        res = get_with_retries("/tasks")
        tasks = res.json()
        return render_template("index.html", tasks=tasks)
    except Exception as e:
        return f"<h1>Error contacting backend</h1><p>{e}</p>", 500

@app.route("/add", methods=["POST"])
def add_task():
    title = request.form.get("title")
    try:
        wait_for_backend()
        post_with_retries("/tasks", {"title": title})
    except Exception as e:
        return f"<h1>Error adding task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

@app.route("/delete/<int:task_id>")
def delete_task(task_id):
    try:
        wait_for_backend()
        delete_with_retries(f"/tasks/{task_id}")
    except Exception as e:
        return f"<h1>Error deleting task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

if __name__ == "__main__":
    print("🚀 Starting frontend server...")
    app.run(host="0.0.0.0", port=8080)
