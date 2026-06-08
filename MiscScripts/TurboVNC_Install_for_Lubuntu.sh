#!/bin/bash
# ============================================================
# Lubuntu 26.04 — TurboVNC + Login Screen Unattended Installer
# Run as root: sudo su, then bash install-turbovnc.sh
# ============================================================

set -e

echo "============================================"
echo " TurboVNC Installer for Lubuntu 26.04"
echo "============================================"

# ── Step 1: Download and install TurboVNC ──────────────────
echo "[1/8] Installing TurboVNC..."
wget -q https://github.com/TurboVNC/turbovnc/releases/download/3.3/turbovnc_3.3_amd64.deb
apt install ./turbovnc_3.3_amd64.deb -y
rm -f ./turbovnc_3.3_amd64.deb

# ── Step 2: Set VNC password non-interactively ─────────────
echo "[2/8] Setting VNC password..."
mkdir -p /root/.vnc
printf "Passw0rd\nPassw0rd\nn\n" | /opt/TurboVNC/bin/vncpasswd

# ── Step 3: Install support tools ─────────────────────────
echo "[3/8] Installing support tools..."
apt install -y python3-gi gir1.2-gtk-3.0 gcc net-tools libxcb-cursor0

# ── Step 4: Create GTK login script ───────────────────────
echo "[4/8] Creating GTK login script..."
cat > /usr/local/bin/vnc-login << 'EOF'
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import subprocess
import os

def show_login():
    dialog = Gtk.Dialog(title="Login")
    dialog.set_default_size(350, 50)
    dialog.set_resizable(False)
    dialog.set_keep_above(True)

    screen = Gdk.Screen.get_default()
    screen_w = screen.get_width()
    screen_h = screen.get_height()
    dialog.move((screen_w - 350) // 2, (screen_h - 220) // 2)

    box = dialog.get_content_area()
    box.set_spacing(10)
    box.set_margin_top(15)
    box.set_margin_bottom(15)
    box.set_margin_start(15)
    box.set_margin_end(15)

    # Username row
    user_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    user_label = Gtk.Label(label="Username:")
    user_label.set_width_chars(10)
    user_label.set_xalign(0)
    user_entry = Gtk.Entry()
    user_entry.set_hexpand(True)
    user_box.pack_start(user_label, False, False, 0)
    user_box.pack_start(user_entry, True, True, 0)
    box.pack_start(user_box, False, False, 0)

    # Password row
    pass_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    pass_label = Gtk.Label(label="Password:")
    pass_label.set_width_chars(10)
    pass_label.set_xalign(0)
    pass_entry = Gtk.Entry()
    pass_entry.set_visibility(False)
    pass_entry.set_hexpand(True)
    pass_box.pack_start(pass_label, False, False, 0)
    pass_box.pack_start(pass_entry, True, True, 0)
    box.pack_start(pass_box, False, False, 0)

    # Show password checkbox
    show_cb = Gtk.CheckButton(label="Show Password")
    show_cb.connect("toggled", lambda w: pass_entry.set_visibility(w.get_active()))
    box.pack_start(show_cb, False, False, 0)

    # Error label
    error_label = Gtk.Label(label="")
    box.pack_start(error_label, False, False, 0)

    # Login button
    dialog.add_button("Login", Gtk.ResponseType.OK)
    pass_entry.connect("activate", lambda w: dialog.response(Gtk.ResponseType.OK))

    dialog.show_all()

    while True:
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            username = user_entry.get_text().strip()
            password = pass_entry.get_text()

            if not username or not password:
                error_label.set_markup('<span foreground="red">Please enter username and password.</span>')
                continue

            result = subprocess.run(
                ["su", "-", username, "-c", "true"],
                input=password + "\n",
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                dialog.destroy()
                while Gtk.events_pending():
                    Gtk.main_iteration()
                env = os.environ.copy()
                env.update({
                    "DISPLAY": ":1",
                    "HOME": f"/home/{username}",
                    "USER": username,
                    "LOGNAME": username,
                    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
                })
                subprocess.run(["su", "-", username, "-c", "DISPLAY=:1 startlxqt"], env=env)
                return
            else:
                error_label.set_markup('<span foreground="red">Login failed. Please try again.</span>')
                pass_entry.set_text("")
        else:
            continue

if __name__ == "__main__":
    while True:
        show_login()
EOF
chmod +x /usr/local/bin/vnc-login

# ── Step 5: Create xstartup ────────────────────────────────
echo "[5/8] Creating xstartup..."
mkdir -p /root/.vnc
cat > /root/.vnc/xstartup << 'EOF'
#!/bin/bash
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

xhost +local: > /dev/null 2>&1
/usr/local/bin/vnc-login
EOF
chmod +x /root/.vnc/xstartup

# ── Step 6: Create systemd service ────────────────────────
echo "[6/8] Creating systemd service..."
cat > /etc/systemd/system/turbovnc.service << 'EOF'
[Unit]
Description=TurboVNC Server
After=network.target sddm.service
Requires=sddm.service

[Service]
Type=forking
User=root
ExecStartPre=/bin/sleep 5
ExecStart=/opt/TurboVNC/bin/vncserver :1 -geometry 1280x800 -depth 24 -rfbport 5901 -xstartup /root/.vnc/xstartup
ExecStop=/opt/TurboVNC/bin/vncserver -kill :1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable turbovnc
systemctl start turbovnc

# ── Step 7: Configure skel for new users ──────────────────
echo "[7/8] Configuring default LXQt environment for new users..."
BASEUSER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$BASEUSER" ] && [ -d "/home/$BASEUSER/.config/lxqt" ]; then
    mkdir -p /etc/skel/.config
    cp -r /home/$BASEUSER/.config/lxqt /etc/skel/.config/
    cp -r /home/$BASEUSER/.config/pcmanfm-qt /etc/skel/.config/ 2>/dev/null || true
    echo "    Copied LXQt config from $BASEUSER to /etc/skel"
else
    echo "    WARNING: Could not find base user config. Run manually after setup."
fi

# ── Step 8: Verify ────────────────────────────────────────
echo "[8/8] Verifying installation..."
sleep 3
if ss -tlnp | grep -q 5901; then
    echo ""
    echo "============================================"
    echo " Installation complete!"
    echo " TurboVNC is listening on port 5901"
    echo " VNC password: Passw0rd"
    echo "============================================"
else
    echo ""
    echo "WARNING: Port 5901 not detected. Check status with:"
    echo "  systemctl status turbovnc"
    echo "  cat /root/.vnc/lab-virtualmachine:1.log"
fi
