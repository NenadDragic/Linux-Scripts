# Copy USB - Log

Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then deletes the source directory.

## Commands

```bash
rsync -av --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

rm -rf /volumeUSB1/usbshare/Log/
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
bash "Copy USB - Log.sh"
```

Ensure the USB drive is mounted at `/volumeUSB1/usbshare/` before running.
