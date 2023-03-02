#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

# Update
sudo apt update
sudo apt upgrade -y

# Bind 9
sudo add-apt-repository ppa:isc/bind -y
sudo apt update
sudo apt-get install bind9 bind9utils bind9-doc -y