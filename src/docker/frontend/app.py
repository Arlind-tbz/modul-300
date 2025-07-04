from flask import Flask, render_template, request, redirect, url_for
import requests
import os
import time

app = Flask(__name__)
BACKEND_API = os.environ.get("BACKEND_API", "http://backend:5000/api")  # use env var if set

def wait_for_backend(url, delay=5):
    attempt = 1
    while True:
        try:
            res = requests.get(f"{url}/tasks")
            if res.status_code == 200:
                print("✅ Backend is ready.")
                return
        except requests.exceptions.ConnectionError:
            print(f"⏳ Waiting for backend... attempt {attempt}")
            attempt += 1
            time.sleep(delay)

@app.route("/", methods=["GET"])
def index():
    try:
        res = requests.get(f"{BACKEND_API}/tasks")
        tasks = res.json()
        return render_template("index.html", tasks=tasks)
    except Exception as e:
        return f"<h1>Error contacting backend</h1><p>{e}</p>", 500

@app.route("/add", methods=["POST"])
def add_task():
    title = request.form.get("title")
    try:
        requests.post(f"{BACKEND_API}/tasks", json={"title": title})
    except Exception as e:
        return f"<h1>Error adding task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

@app.route("/delete/<int:task_id>")
def delete_task(task_id):
    try:
        requests.delete(f"{BACKEND_API}/tasks/{task_id}")
    except Exception as e:
        return f"<h1>Error deleting task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

if __name__ == "__main__":
    wait_for_backend(BACKEND_API)
    app.run(host="0.0.0.0", port=8080)
