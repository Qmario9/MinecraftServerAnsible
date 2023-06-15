#!/bin/bash
sudo mkdir /opt/minecraft
sudo mkdir /opt/minecraft/server
cd /opt/minecraft/server
sudo wget https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar


#removing sudo
if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run with root privileges."
  exit 1
fi

# Create a backup of the sudoers file
cp /etc/sudoers /etc/sudoers.bak

# Add a line to the sudoers file to grant root privileges to the user
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Save and exit the sudoers file
visudo -c

# Check if the sudoers file syntax is valid
if [[ $? -eq 0 ]]; then
  echo "User 'ubuntu' now has root privileges without requiring sudo password."
else
  echo "There was an error in the sudoers file. Restoring the backup."
  cp /etc/sudoers.bak /etc/sudoers
fi

