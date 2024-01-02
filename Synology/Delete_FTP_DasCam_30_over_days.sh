#!/bin/bash

find /volume1/Ftp/DashCam -type f -mtime +30  | xargs rm -f