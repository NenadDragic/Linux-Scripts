# Copy Loppe files

Copies the `Loppe` directory from a remote host to the NAS, then lists the destination contents.

## Commands

```bash
scp -r admina@10.0.0.215:/home/admina/Loppe/ /volume1/Dragic/Rap

ls -al /volume1/Dragic/Rap/Loppe
```

## Options

| Option | Description |
| ------ | ----------- |
| `scp -r` | Recursively copy a directory over SSH |
| `admina@10.0.0.215` | Remote user and host IP |
| `/home/admina/Loppe/` | Source directory on remote host |
| `/volume1/Dragic/Rap` | Destination directory on NAS |
| `ls -al` | List destination contents with details |

## Usage

```bash
bash "Copy Loppe files.sh"
```

Ensure SSH access to `10.0.0.215` is available before running.
