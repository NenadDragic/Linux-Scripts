# Backup USB Umount

Dette script afmonterer backup-USB sikkert og forsøger derefter at ejecte enheden.

## Script

```bash
#!/bin/bash
MOUNT_POINT="/mnt/usb/Backup"
UUID="cff68436-8fe9-422f-8ce8-750206be924f"

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
