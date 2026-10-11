#!/bin/bash
set -e
cd "$(dirname "$0")"
sudo install -m 755 pl1-cap /usr/local/bin/pl1-cap
sudo install -m 755 pl1-cap-set /usr/local/bin/pl1-cap-set
[ -e /etc/pl1-cap.conf ] || sudo install -m 644 pl1-cap.conf /etc/pl1-cap.conf
sudo install -m 644 pl1-cap.service /etc/systemd/system/pl1-cap.service
sudo systemctl daemon-reload
sudo systemctl enable --now pl1-cap.service
systemctl status pl1-cap.service --no-pager
