#!/bin/bash
sudo systemctl disable --now pl1-cap.service
sudo rm -f /etc/systemd/system/pl1-cap.service /usr/local/bin/pl1-cap
sudo systemctl daemon-reload
