#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

# Update
apt update
apt upgrade -y

# Bind 9
add-apt-repository ppa:isc/bind -y
apt update

apt-get install -y bind9 bind9utils bind9-doc

systemctl enable named
systemctl start named
