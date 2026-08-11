# Reboot

Immediately reboots the system.

> **WARNING:** `shutdown -r now` triggers an **IMMEDIATE, irreversible reboot** with **no confirmation prompt or cancel window**. It forcibly terminates all running processes, scheduled tasks, and any active file transfer/SFTP/SCP sessions, and drops all client connections instantly. Do not run this unless you intend the NAS to reboot right now.

## Command

```bash
sudo shutdown -r now
```

## Options

| Option | Description |
| ------ | ----------- |
| `-r` | Reboot after shutdown |
| `now` | Execute immediately with no delay |

## Usage

```bash
bash "Reboot.sh"
```
