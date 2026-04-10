#!/bin/bash
# Version:      1.1
# Date:         2026-03-26
# Test Run:     2026-03-29
# Developper:   Nenad(a)dragic(.)com

scp -r admina@10.0.0.149:/home/admina/gps_monitor/logs/csv/ /volume1/Dragic/Rap/GPS_log

ls -alh /volume1/Dragic/Rap/GPS_log/csv