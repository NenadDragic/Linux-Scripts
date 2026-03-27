# Copy USB - Devices

Copies all files from a USB drive to `/volume1/NetBackup/`, removing source files after transfer, then deletes the source directory.

## Commands

```bash
sudo rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/ \
  /volume1/NetBackup/

sudo rm -rf /volumeUSB1/usbshare/
```

## Options

| Option | Description |
| ------ | ----------- |
| `-a` | Archive mode — preserves permissions, timestamps, symlinks, etc. |
| `-v` | Verbose output |
| `--progress` | Show transfer progress |
| `--remove-source-files` | Delete source files after successful transfer |
| `rm -rf` | Remove the now-empty source directory |

## Usage

```bash
bash "Copy USB - Devices.sh"
```

Ensure the USB drive is mounted at `/volumeUSB1/usbshare/` before running.
