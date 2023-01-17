# printerbox_device
Compose the dockers running in the printerbox device

Installation guide:


docker-compose pull

docker volume create --name=printer_labels

./install_printer.sh

docker-compose up -d

vim.tiny config/printerbox_config.json

