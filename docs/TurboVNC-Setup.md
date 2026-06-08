# Lubuntu 26.04 — TurboVNC with Login Screen Setup

This document covers the complete installation and configuration of TurboVNC with a GTK login screen on Lubuntu 26.04, suitable for Skillable lab environments where students may need to log in as different user accounts.

---

## Prerequisites

Run all commands as root:

```bash
sudo su
```

---

## Step 1: Download and install TurboVNC

```bash
wget https://github.com/TurboVNC/turbovnc/releases/download/3.3/turbovnc_3.3_amd64.deb
apt install ./turbovnc_3.3_amd64.deb -y
```

---

## Step 2: Set the VNC password

```bash
/opt/TurboVNC/bin/vncpasswd
```

---

## Step 3: Install support tools

```bash
apt install python3-gi gir1.2-gtk-3.0 gcc net-tools libxcb-cursor0 -y
```

---

## Step 4: Create the GTK login script

```bash
tee /usr/local/bin/vnc-login << 'EOF'
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

    # Center on screen
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
```

---

## Step 5: Create the VNC xstartup script

```bash
mkdir -p /root/.vnc
tee /root/.vnc/xstartup << 'EOF'
#!/bin/bash
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

xhost +local: > /dev/null 2>&1
/usr/local/bin/vnc-login
EOF
chmod +x /root/.vnc/xstartup
```

---

## Step 6: Create the systemd service for autostart

```bash
tee /etc/systemd/system/turbovnc.service << 'EOF'
[Unit]
Description=TurboVNC Server
After=network.target

[Service]
Type=forking
User=root
ExecStart=/opt/TurboVNC/bin/vncserver :1 -geometry 1280x800 -depth 24 -rfbport 5901 -xstartup /root/.vnc/xstartup -novtswitch -nohttpd
ExecStop=/opt/TurboVNC/bin/vncserver -kill :1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable turbovnc
systemctl start turbovnc
```

---

## Step 7: Confirm VNC is listening

```bash
ss -tlnp | grep 5901
```

You should see `0.0.0.0:5901` in the output.

---

## Step 8: Configure default LXQt environment for new users

This copies the LXQt desktop configuration from the initial user account into `/etc/skel` so that any new user created on the system automatically gets a properly configured desktop with icons.

Replace `labuser` below with the name of your configured base user if different:

```bash
mkdir -p /etc/skel/.config
cp -r /home/labuser/.config/lxqt /etc/skel/.config/
cp -r /home/labuser/.config/pcmanfm-qt /etc/skel/.config/
```

---

## Step 9: Creating additional lab users

Any new user created with the `-m` flag will automatically inherit the LXQt configuration from skel:

```bash
useradd -m -s /bin/bash username
passwd username
```

---

## Notes

- The VNC endpoint should be configured to connect on port **5901**.
- The login dialog supports username/password entry with a show/hide password toggle.
- After a user logs out of LXQt, the login dialog automatically reappears for the next user.
- TurboVNC supports dynamic screen resizing — the desktop will resize to fit the browser window automatically.
- The VNC server runs as root solely to support the login screen. User sessions run under the authenticated user's account.
