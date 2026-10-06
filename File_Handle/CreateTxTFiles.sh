#!/bin/bash

OUTDIR="${1:-$HOME/testfiles}"
COUNT=1
SIZE_MB=500

mkdir -p "$OUTDIR"

echo "Opretter $COUNT filer á ${SIZE_MB} MB i: $OUTDIR"

for i in $(seq 1 $COUNT); do
    dd if=/dev/urandom of="$OUTDIR/file_$(printf "%04d" $i).bin" bs=1M count=$SIZE_MB 2>/dev/null
    if (( i % 100 == 0 )); then
        echo "  $i / $COUNT færdig..."
    fi
done

echo "Færdig! $(du -sh "$OUTDIR" | cut -f1) brugt."
