# Auto-montering af USB-drev på Linux

## Baggrund

Når du sætter et USB-drev til på en desktop Linux (f.eks. Ubuntu/Debian med GNOME), vil systemet normalt auto-montere det under `/media/<brugernavn>/<label>` via en service kaldet **udisks2**. Det er praktisk til hverdagsbrug, men giver ikke kontrol over mountpunkt.

Ønsker du at drevet altid monteres på et fast sti — f.eks. `/mnt/usb/Backup` — skal du:

1. Forhindre udisks2 i at montere drevet
2. Lade systemet montere det det rigtige sted automatisk

---

## Forudsætninger

### Find enhedsnavnet

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
```

Drevet vil typisk hedde `/dev/sda1` eller `/dev/sdb1` — afhænger af hvad der er tilsluttet.

### Find UUID

UUID er et unikt ID for partitionen, som ikke ændrer sig selv om drevet skifter enhedsnavn (sda/sdb osv.):

```bash
sudo blkid /dev/sdb1
```

Eksempel output:
```
/dev/sdb1: LABEL="Dragic" UUID="79acd543-afcd-4e0a-adc0-e3168df7b57e" TYPE="ext4"
```

Gem UUID-værdien — den bruges i alle efterfølgende trin.

---

## Opsætning

### Trin 1 — Opret mountpunkt

```bash
sudo mkdir -p /mnt/usb/Backup
```

### Trin 2 — Opret systemd service

Systemd-servicen udfører selve mount-kommandoen. udev kan ikke køre `mount` direkte i sit begrænsede miljø, derfor bruges en service som mellemled.

```bash
sudo nano /etc/systemd/system/backup-mount.service
```

```ini
[Unit]
Description=Mount Backup USB

[Service]
Type=oneshot
ExecStartPre=/bin/mkdir -p /mnt/usb/Backup
ExecStart=/bin/mount UUID=79acd543-afcd-4e0a-adc0-e3168df7b57e /mnt/usb/Backup
RemainAfterExit=yes
ExecStop=/bin/umount /mnt/usb/Backup
```

Aktivér servicen:
```bash
sudo systemctl daemon-reload
```

### Trin 3 — Opret udev regel

udev overvåger hardware-hændelser. Når drevet tilsluttes, aktiverer reglen servicen. `UDISKS_IGNORE` forhindrer udisks2 i at montere drevet på `/media/...` først.

```bash
sudo nano /etc/udev/rules.d/99-backup-mount.rules
```

```
# Forhindre udisks2 i at auto-mounte drevet
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="79acd543-afcd-4e0a-adc0-e3168df7b57e", ENV{UDISKS_IGNORE}="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="backup-mount.service"

# Stop servicen (afmonter) når drevet trækkes ud
ACTION=="remove", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="79acd543-afcd-4e0a-adc0-e3168df7b57e", RUN+="/bin/systemctl stop backup-mount.service"
```

Genindlæs udev:
```bash
sudo udevadm control --reload-rules
```

---

## Sådan fungerer det

```
Drev tilsluttes
      │
      ▼
   udev opdager hændelsen
      │
      ├── Sætter UDISKS_IGNORE=1  →  udisks2 monterer IKKE
      │
      └── Starter backup-mount.service
                │
                ▼
         mount UUID=... /mnt/usb/Backup ✅

Drev trækkes ud
      │
      ▼
   udev opdager remove-hændelsen
      │
      └── Stopper backup-mount.service
                │
                ▼
         umount /mnt/usb/Backup ✅
```

---

## Validering

Tjek at drevet er monteret korrekt efter tilslutning:

```bash
lsblk
df -h | grep Backup
ls /mnt/usb/Backup
```

Forventet output fra `lsblk`:
```
sdb    8:16  0  1.8T  0 disk
└─sdb1 8:17  0  1.8T  0 part  /mnt/usb/Backup
```

---

## Afmontering

Inden du trækker drevet ud manuelt, sørg for at du ikke selv står i mappen:

```bash
cd ~
sudo umount /mnt/usb/Backup
```

Fejlen `target is busy` betyder at en proces (eller din terminal) bruger mountpunktet. Find synderen med:

```bash
lsof /mnt/usb/Backup
fuser -m /mnt/usb/Backup
```

Hvis ingen processer vises men umount stadig fejler, brug lazy unmount:

```bash
sudo umount -l /mnt/usb/Backup
```

Lazy unmount afmonterer drevet i baggrunden når det ikke længere er i brug. Tjek hvornår det er sikkert at trække ud:

```bash
lsblk | grep sdb
```

Når mountpunktet er tomt i output, er drevet afmonteret.

---

## Filer og placeringer

| Fil | Formål |
|-----|--------|
| `/etc/udev/rules.d/99-backup-mount.rules` | Opdager tilslutning/frakobling |
| `/etc/systemd/system/backup-mount.service` | Udfører mount/umount |
| `/mnt/usb/Backup` | Mountpunkt |
