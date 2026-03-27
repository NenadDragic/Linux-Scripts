# Copy GPS log files

Copies GPS monitor CSV logs from a remote host to the NAS, then lists the destination contents.

## Commands

```bash
scp -r admina@10.0.0.149:/home/admina/gps_monitor/logs/csv/ /volume1/Dragic/Rap/GPS_log

ls -al /volume1/Dragic/Rap/GPS_log/csv
```

## Options

| Option | Description |
| ------ | ----------- |
| `scp -r` | Recursively copy a directory over SSH |
| `admina@10.0.0.149` | Remote user and host IP |
| `/home/admina/gps_monitor/logs/csv/` | Source directory on remote host |
| `/volume1/Dragic/Rap/GPS_log` | Destination directory on NAS |
| `ls -al` | List destination contents with details |

## Usage

```bash
bash "Copy GPS log files.sh"
```

Ensure SSH access to `10.0.0.149` is available before running.
