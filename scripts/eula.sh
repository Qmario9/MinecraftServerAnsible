#!/bin/bash

java -Xmx1024M -Xms1024M -jar server.jar nogui
sed -i 's/false/true/g' eula.txt
sudo killall -9 java
sudo systemctl daemon-reload
sudo systemctl enable mineFinal.service
sudo systemctl start mineFinal.service