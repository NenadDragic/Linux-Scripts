# Create_New_Session

This script prompts for a name and starts a new named GNU `screen` session with it, attaching the current terminal to that session.

---

## Usage

```console
chmod +x Create_New_Session.sh
bash Create_New_Session.sh
```

Run it from any directory — it does not operate on files and has no working-directory dependency.

Prerequisites:

- GNU `screen` must be installed.

---

## What the Script Does

### Step 1 – Prompt for a session name

`read -p "Enter a name for the new session: " session_name` prompts the user and stores whatever they type in `session_name`.

### Step 2 – Start the named session

`screen -S "$session_name"` starts a new `screen` session using that name and attaches the current terminal to it in the foreground — the user is dropped straight into the new session.

---

## Notes

- No validation is performed on the entered name — an empty or unusual value is passed straight through to `screen -S`, which will apply its own defaults/errors.
- The session name is not sanitized, but it is double-quoted when passed to `screen`, so spaces and most special characters in the name are handled safely.
- The script does not check whether `screen` is installed before calling it; if it's missing, the shell will report a "command not found" error.
- The new session is started attached (in the foreground), not detached — the invoking shell is effectively replaced by the screen session until the user detaches from it.
