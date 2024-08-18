#!/bin/bash


sudo yum update -y
sudo yum install httpd -y
sudo systemctl enable httpd
sudo echo "This is my Auto Scaled server" >/var/www/html/index.html
sudo systemctl restart httpd

