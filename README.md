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
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.orig
echo -e "# Total limit for all journals:\nSystemMaxUse=4G\n# Limit for individual files before rotation:\nSystemMaxFileSize=1G" | sudo tee -a /etc/systemd/journald.conf
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
# 1️⃣ Create systemd override directory for Docker
sudo mkdir -p /etc/systemd/system/docker.service.d

# 2️⃣ Create override file to depend on DNS precheck
sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<'EOF'
[Unit]
Requires=docker-dns-ready.service
After=docker-dns-ready.service
EOF

# 3️⃣ Create the DNS precheck service
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

# 4️⃣ Reload systemd to pick up new units
sudo systemctl daemon-reload

# 5️⃣ Enable the DNS precheck so it runs at boot
sudo systemctl enable docker-dns-ready.service


```
Fixup for DNS problem
```
echo -e '[Unit]\nDescription=Restart docker if DNS stops working\nAfter=docker.service\nBindsTo=docker.service\n\n[Service]\nType=simple\nWorkingDirectory=/home/pi/printerbox_device/scripts\nExecStart=/bin/bash -c ./restart-docker-if-dns-fails.sh\nUser=root\nGroup=root\nRestart=always\nRestartSec=5s\n\n[Install]\nWantedBy=default.target\n' | sudo tee /etc/systemd/system/restart-docker-if-dns-fails.service
sudo systemctl enable restart-docker-if-dns-fails.service && sudo systemctl start restart-docker-if-dns-fails.service
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




