#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo -s)"
  exit 1
fi

echo "=========================================="
echo "   Installing ZiVPN Web Panel...          "
echo "=========================================="

apt update
apt install python3 python3-pip python3-flask wget curl -y

mkdir -p /etc/zivpn/templates
cd /etc/zivpn

# 1. Creating app.py
cat << 'EOF' > app.py
from flask import Flask, render_template, request, redirect, url_for, session
import subprocess

app = Flask(__name__)
app.secret_key = "zivpn_secret_key"

ADMIN_USER = "khaing"
ADMIN_PASS = "khaing"

@app.route('/', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        if request.form['username'] == ADMIN_USER and request.form['password'] == ADMIN_PASS:
            session['logged_in'] = True
            return redirect(url_for('dashboard'))
        else:
            error = 'Invalid username or password'
    return render_template('login.html', error=error)

@app.route('/dashboard')
def dashboard():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    return "<h1>Welcome to ZiVPN Dashboard</h1><p>Manage your users here.</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=19432)
EOF

# 2. Creating templates/login.html
cat << 'EOF' > templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZIVPN Panel Login</title>
    <style>
        body { margin: 0; padding: 0; height: 100vh; background: linear-gradient(135deg, #f43f5e, #a855f7, #22c55e); display: flex; justify-content: center; align-items: center; font-family: sans-serif; }
        .login-box { background: #111827; padding: 40px; border-radius: 15px; text-align: center; color: white; width: 300px; }
        input { width: 100%; padding: 10px; margin: 10px 0; border-radius: 5px; border: 1px solid #374151; background: #1f2937; color: white; box-sizing: border-box; }
        button { width: 100%; padding: 10px; background: #3b82f6; border: none; color: white; border-radius: 5px; cursor: pointer; font-weight: bold; margin-top: 10px; }
        .error { color: #f43f5e; margin-top: 10px; font-size: 14px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>ZIVPN Panel Login</h2>
        <form method="POST">
            <input type="text" name="username" placeholder="Username" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Login</button>
        </form>
        {% if error %}<div class="error">{{ error }}</div>{% endif %}
    </div>
</body>
</html>
EOF

# Setting up Background Service
cat <<EOF > /etc/systemd/system/zivpn-web.service
[Unit]
Description=ZiVPN Web Panel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/zivpn/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Open Port and Start Service
ufw allow 19432/tcp
systemctl daemon-reload
systemctl enable zivpn-web
systemctl start zivpn-web

echo "=========================================="
echo " ZiVPN Web Panel Installed Successfully!   "
echo " URL -> http://YOUR_VPS_IP:19432          "
echo "=========================================="
