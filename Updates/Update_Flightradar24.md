# Update Flightradar24

This script updates the Flightradar24 feeder (`fr24feed`) to a specific, hardcoded version by stopping the running service, removing the old package, downloading and installing a fixed `.deb` package, and restarting the service.

---

## Usage

```console
chmod +x Update_Flightradar24.sh
bash Update_Flightradar24.sh
```

Run it from a directory the invoking user can write to (the downloaded `.deb` file is saved to the current working directory). The script does not check for root itself; each privileged command is individually prefixed with `sudo`, so the invoking user will be prompted for their password as needed.

Prerequisites:

- `fr24feed` (Flightradar24 feeder) previously installed and registered as a systemd service.
- `sudo`, `systemctl`, `dpkg`, and `wget` available on the system.
- Network access to `repo-feed.flightradar24.com`.
- The invoking user must have sudo privileges.

---

## What the Script Does

### Step 1 – Stop the Flightradar24 service
Runs `sudo systemctl stop fr24feed` to stop the running feeder before making changes.

### Step 2 – Remove the old package
Runs `sudo dpkg -r fr24feed` to remove the currently installed `fr24feed` package (configuration files are kept, since `-r` is a non-purging removal).

### Step 3 – Download the new package
Runs `wget` to fetch `fr24feed_1.0.28-1_amd64.deb` from `https://repo-feed.flightradar24.com/linux_x86_64_binaries/`, saving it into the current working directory.

### Step 4 – Install the new package
Runs `sudo dpkg -i fr24feed_1.0.28-1_amd64.deb` to install the downloaded package.

### Step 5 – Start the Flightradar24 service
Runs `sudo systemctl start fr24feed` to bring the feeder back up on the new version.

---

## Notes

- **Hardcoded version**: the package filename/version (`fr24feed_1.0.28-1_amd64.deb`) is hardcoded in the URL and install command. The script does not fetch "the latest" version despite the intent — it must be manually edited whenever a new fr24feed release comes out, or it will simply reinstall version 1.0.28-1.
- **No error handling**: if the `wget` download fails (e.g. that version was removed from the repo, or no network), the subsequent `dpkg -i` will fail because the file won't exist, but the script has no checks and will still attempt to (re)start the service afterward.
- **Service downtime**: `fr24feed` is stopped for the entire duration of the removal/download/install, so data feed submission is interrupted until Step 5 completes.
- The downloaded `.deb` file is left behind in the working directory after the script finishes; it is not cleaned up.
- Does not require root for the whole script (unlike the other scripts in this folder) — it relies on per-command `sudo` instead of a `whoami` check.
