#!/bin/bash
apt update -y
apt install -y nginx
systemctl enable nginx
systemctl start nginx
echo "<h1>Nginx Server. Hostname is $(hostname -f)</h1>" > /var/www/html/index.html