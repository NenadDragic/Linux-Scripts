(du -ha --max-depth=1 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/DashCam/ 2>/dev/null | grep -vE "total$|/volume1/DashCam/$" | sort -k2); du -shc /volume1/DashCam/ 2>/dev/null
