# Install a fresh printerbox

## Update printer with settings from a Windows PC

Use printerbox_instillinger.dat to setup printer

## Installation on the RPI

Install Raspberion OS on the flash card (RaspberianOS Lite 64bit)

Choose hostname, password, ssh access, and timezone

Update apt
```
sudo apt update && sudo apt upgrade
```   

Save idle power
```
sudo apt-get install cpufrequtils &&
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
```

Setup docker  and logout
Follow the instructions https://docs.docker.com/engine/install/debian/
```
sudo systemctl enable docker &&    
sudo usermod -a -G docker pi &&
exit
```

blink1 support
```
sudo apt install libhidapi-hidraw0
```

Limit Journal diskspace usage
```
sudo sed -i 's/^#*SystemMaxUse=.*/SystemMaxUse=200M/' /etc/systemd/journald.conf
sudo sed -i 's/^#*SystemMaxFileSize=.*/SystemMaxFileSize=50M/' /etc/systemd/journald.conf
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.orig
```

Clone project
```
git clone https://github.com/groskopf/printerbox_device.git
cd printerbox_device
```

Rename the printer ID and add access token
```
vim.tiny config/printerbox_config.json 
```

Power on printer and connect it
```
docker compose pull
docker volume create --name=printer_labels
./install_printer.sh
docker compose up -d
```
Delay docker untill we are online
```
# Create systemd override directory for Docker
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create override file to depend on DNS precheck
sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<'EOF'
[Unit]
Requires=docker-dns-ready.service
After=docker-dns-ready.service
EOF

# Create the DNS precheck service
sudo tee /etc/systemd/system/docker-dns-ready.service > /dev/null <<'EOF'
[Unit]
Description=Wait for working DNS before starting Docker
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo Waiting for DNS to resolve google.com ...; while ! getent hosts google.com >/dev/null 2>&1; do echo DNS not ready, retrying in 5s...; sleep 5; done; echo DNS is ready!"

[Install]
WantedBy=docker.service
EOF

# Reload systemd to pick up new units
sudo systemctl daemon-reload

# Enable the DNS precheck so it runs at boot
sudo systemctl enable docker-dns-ready.service

```
Remove old Fixup for DNS problem
```
sudo systemctl disable restart-docker-if-dns-fails.service
sudo rm /etc/systemd/system/restart-docker-if-dns-fails.service
```
Restart docker ip primary interface changes(Fixup for DNS problem)
```
# Trigger an systemd service when network stare changes
sudo mkdir -p /etc/NetworkManager/dispatcher.d

# Create override file to depend on DNS precheck
sudo tee /etc/NetworkManager/dispatcher.d/99-check-if-dns-changes > /dev/null <<'EOF'
#!/bin/sh
IFACE="$1"
STATE="$2"

if [ "$STATE" = "up" ] || [ "$STATE" = "down" ]; then
    # Give NM a few seconds to settle routing and DNS
    sleep 3
    systemctl start restart-docker-if-network-changed.service
fi
EOF
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-check-if-dns-changes

# Service that trigger default network check
sudo tee /etc/systemd/system/restart-docker-if-network-changed.service >/dev/null <<'EOF'
[Unit]
Description=Restart Docker if default interface changes (usb0 <-> eth0)
After=network-online.target
Wants=network-online.target

After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restart-docker-if-network-changed.sh
EOF

# Script that restart docker if interface changed
sudo tee /usr/local/bin/restart-docker-if-network-changed.sh >/dev/null <<'EOF'
#!/bin/sh
set -e

STATE_FILE="/run/docker_last_iface"

CURRENT_IFACE="$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/ {print $5; exit}')"
[ -z "$CURRENT_IFACE" ] && CURRENT_IFACE="none"

LAST_IFACE=""
[ -f "$STATE_FILE" ] && LAST_IFACE="$(cat "$STATE_FILE")"

echo Current interface: "$CURRENT_IFACE", Last interface: "$STATE_FILE"

# Only restart if the interface changed to eth0 or usb0
if [ "$CURRENT_IFACE" != "$LAST_IFACE" ] && \
   { [ "$CURRENT_IFACE" = "eth0" ] || [ "$CURRENT_IFACE" = "usb0" ]; }; then
    echo "Interface changed from '$LAST_IFACE' to '$CURRENT_IFACE', restarting Docker..."
    systemctl restart docker.service
fi
EOF
sudo chmod +x /usr/local/bin/restart-docker-if-network-changed.sh

# Reload systemd to pick up new units
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```
Setup route metrics for USB modem
```
sudo nmcli connection modify "Wired connection 1" ipv4.route-metric 100 ipv6.route-metric 100
sudo nmcli connection modify "Wired connection 2" ipv4.route-metric 200 ipv6.route-metric 200
sudo nmcli connection down "Wired connection 1" && sudo nmcli connection up "Wired connection 1"
sudo nmcli connection down "Wired connection 2" && sudo nmcli connection up "Wired connection 2"
```

Reverse SSH setup

Generate SSH key

```
ssh-keygen && cat /home/pi/.ssh/id_rsa.pub  
```

Upload key to cloud.google.com

Change port and user name ti printerbox-n
```
echo -e '[Unit]\nDescription=Reverse SSH connection\nAfter=network.target\n\n[Service]\nType=simple\nExecStart=/usr/bin/ssh -vvv -g -N -T -o "ServerAliveInterval=10" -o "ExitOnForwardFailure=yes" -R 6000:localhost:22 printerbox-1@34.141.14.43\nUser=pi\nGroup=pi\nRestart=always\nRestartSec=5s\n\n[Install]\nWantedBy=default.target\n' | sudo tee /etc/systemd/system/ssh-reverse.service && sudo vim.tiny /etc/systemd/system/ssh-reverse.service  

```
Test !

```
/usr/bin/ssh printerbox-2@api.printerboks.dk  
sudo systemctl enable ssh-reverse.service && sudo systemctl start ssh-reverse.service && sudo systemctl status ssh-reverse.service
```



# From a windows PAC  Update LED
'blink1-tool.exe --gobootload'

Update via 'https://dfu.blink1.thingm.com/'

'blink1-tool --setstartup 1,1,2,255 && '




