# Backup USB Umount

Dette script afmonterer backup-USB sikkert og forsøger derefter at ejecte enheden.

## Script

```bash
#!/bin/bash
MOUNT_POINT="/mnt/usb/Backup"
UUID="6b0f406c-bf48-4ecc-9673-d963dc278d9c"

sudo umount "$MOUNT_POINT" && \
sudo eject "/dev/disk/by-uuid/$UUID" && \
echo "USB sikkert fjernet"
```

## Hvad scriptet gør

1. Definerer mountpunktet i variablen `MOUNT_POINT`.
2. Definerer USB-drevets UUID i variablen `UUID`.
3. Kører `umount` på mountpunktet.
4. Hvis afmontering lykkes, kører `eject` på drevet via UUID.
5. Hvis begge kommandoer lykkes, vises beskeden: `USB sikkert fjernet`.

## Bemærk

- Scriptet bruger `sudo`, så brugeren skal have rettigheder til `umount` og `eject`.
- Hvis mountpunktet er i brug, vil `umount` fejle, og de næste kommandoer bliver ikke kørt.
