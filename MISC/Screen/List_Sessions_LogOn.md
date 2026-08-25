# List_Sessions_LogOn

This script lists all running GNU `screen` sessions, prompts for a session ID, and reattaches the current terminal to that session.

---

## Usage

```console
chmod +x List_Sessions_LogOn.sh
bash List_Sessions_LogOn.sh
```

Run it from any directory — it operates on `screen` sessions, not files.

Prerequisites:

- GNU `screen` must be installed, with at least one session already running to connect to.

---

## What the Script Does

### Step 1 – List running sessions

`screen -ls` prints all currently running `screen` sessions along with their IDs/PIDs and names (if any).

### Step 2 – Prompt for a session ID

`read -p "Enter the session ID to connect to: " session_id` prompts the user and stores their input in `session_id`.

### Step 3 – Reattach to the selected session

`screen -r $session_id` reattaches the current terminal to the specified session.

---

## Notes

- `$session_id` is used unquoted in the final command, so an ID containing spaces would be split into multiple arguments; this is normally not an issue since `screen -ls` IDs/names don't contain spaces.
- No validation is performed on the entered ID — if it doesn't match a running session, `screen` will print its own error.
- The script uses plain `screen -r`, not `screen -d -r`: if the target session is already attached elsewhere, `screen` will refuse to attach and suggest using `-d -r` instead — this script does not handle that case for the user.
