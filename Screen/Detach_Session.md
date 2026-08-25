# Detach_Session

This script lists all running GNU `screen` sessions, prompts for a session ID, and detaches that session using `screen`'s command-mode API rather than sending literal `Ctrl+A d` keystrokes.

---

## Usage

```console
chmod +x Detach_Session.sh
bash Detach_Session.sh
```

Run it from any directory — it operates on `screen` sessions, not files.

Prerequisites:

- GNU `screen` must be installed, with at least one session already running to detach from.

---

## What the Script Does

### Step 1 – List running sessions

`screen -ls` prints all currently running `screen` sessions along with their IDs/PIDs and names (if any), so the user can see what's available.

### Step 2 – Prompt for a session ID

`read -p "Enter the session ID to detach from: " session_id` prompts the user and stores their input in `session_id`.

### Step 3 – Detach the selected session

`screen -S $session_id -X detach` tells the named session to detach via `screen`'s `-X` command-mode option, achieving the same result as pressing `Ctrl+A d` inside it.

---

## Notes

- `$session_id` is used unquoted in the final command, so an ID containing spaces would be split into multiple arguments; this is normally not an issue since `screen -ls` IDs/names don't contain spaces.
- No validation is performed on the entered ID — if it doesn't match a running session, `screen` will print its own error (e.g. "No screen session found").
- This only detaches the session; it keeps running in the background and can be reattached later (e.g. with `screen -r`).
