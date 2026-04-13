# Copy USB - Log

Copies log files from a USB drive to `/volume1/NetBackup/Log/`, removing the source files after transfer, then deletes the source directory.

## Commands

```bash
sudo rsync -avL --progress --remove-source-files \
  /volumeUSB1/usbshare/Log/ \
  /volume1/NetBackup/Log/

sudo find /volumeUSB1/usbshare/Log/ -type d -empty -delete

sudo rm -rf /volumeUSB1/usbshare/Log/
```

## Options

| Option | Description |
| ------ | ----------- |
| `-a` | Archive mode — preserves permissions, timestamps, symlinks, etc. |
| `-v` | Verbose output |
| `-L` | Follow symlinks — copies the file/directory the symlink points to |
| `--progress` | Show transfer progress |
| `--remove-source-files` | Delete source files after successful transfer |
| `sudo find -type d -empty -delete` | Delete empty directories left after transfer |
| `sudo rm -rf` | Remove the now-empty source directory |

## Usage

```bash
sudo bash "Copy USB - Log.sh"
```

Ensure the USB drive is mounted at `/volumeUSB1/usbshare/` before running.
