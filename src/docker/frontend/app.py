from flask import Flask, render_template, request, redirect, url_for
import requests
import os
import time

app = Flask(__name__)
BACKEND_HOST = os.getenv("BACKEND_HOST", "backend")
BACKEND_API = f"http://{BACKEND_HOST}:5000/api"

def get_with_retries(endpoint, retries=3, delay=2):
    for attempt in range(retries):
        try:
            res = requests.get(f"{BACKEND_API}{endpoint}")
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            if attempt < retries - 1:
                print(f"⚠️ Failed to GET {endpoint}: {e}. Retrying ({attempt+1}/{retries})...")
                time.sleep(delay)
            else:
                raise e

def post_with_retries(endpoint, data, retries=3, delay=2):
    for attempt in range(retries):
        try:
            res = requests.post(f"{BACKEND_API}{endpoint}", json=data)
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            if attempt < retries - 1:
                print(f"⚠️ Failed to POST {endpoint}: {e}. Retrying ({attempt+1}/{retries})...")
                time.sleep(delay)
            else:
                raise e

def delete_with_retries(endpoint, retries=3, delay=2):
    for attempt in range(retries):
        try:
            res = requests.delete(f"{BACKEND_API}{endpoint}")
            res.raise_for_status()
            return res
        except requests.RequestException as e:
            if attempt < retries - 1:
                print(f"⚠️ Failed to DELETE {endpoint}: {e}. Retrying ({attempt+1}/{retries})...")
                time.sleep(delay)
            else:
                raise e

@app.route("/", methods=["GET"])
def index():
    try:
        res = get_with_retries("/tasks")
        tasks = res.json()
        return render_template("index.html", tasks=tasks)
    except Exception as e:
        return f"<h1>Error contacting backend</h1><p>{e}</p>", 500

@app.route("/add", methods=["POST"])
def add_task():
    title = request.form.get("title")
    try:
        post_with_retries("/tasks", {"title": title})
    except Exception as e:
        return f"<h1>Error adding task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

@app.route("/delete/<int:task_id>")
def delete_task(task_id):
    try:
        delete_with_retries(f"/tasks/{task_id}")
    except Exception as e:
        return f"<h1>Error deleting task</h1><p>{e}</p>", 500
    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
