(du -ha --max-depth=1 --exclude='#recycle' --exclude='@eaDir' --exclude='Log' /volume1/Dragic/ 2>/dev/null | grep -vE "total$|/volume1/Dragic/$" | sort -k2); du -shc /volume1/Dragic/ 2>/dev/null
