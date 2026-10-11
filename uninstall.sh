#!/bin/bash
sudo systemctl disable --now pl1-cap.service
sudo rm -f /etc/systemd/system/pl1-cap.service /usr/local/bin/pl1-cap /usr/local/bin/pl1-cap-set
sudo systemctl daemon-reload
# /etc/pl1-cap.conf is left in place (your tuned caps); remove it by hand if you want.
