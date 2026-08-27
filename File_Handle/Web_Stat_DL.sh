#!/bin/bash

# Downloads Web-Status reports from the NAS to the local Documents folder
rsync -av ElBosso@192.168.1.50:/volume1/Dragic/Rap/Web_Status/ /home/nenad/Documents/Web-Status
