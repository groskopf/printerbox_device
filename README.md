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
`    ``

blink1 support
```
sudo apt install libhidapi-hidraw0
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




