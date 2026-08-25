# Screen Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## GNU Screen Session Management

| Script | Doc | Summary |
|---|---|---|
| `Create_New_Session.sh` | [Create_New_Session.md](Create_New_Session.md) | Prompts the user for a name and starts a new GNU `screen` session with it (`screen -S "$session_name"`). |
| `List_Sessions_LogOn.sh` | [List_Sessions_LogOn.md](List_Sessions_LogOn.md) | Lists all running `screen` sessions (`screen -ls`), then prompts for a session ID and reattaches to it (`screen -r $session_id`). |
| `Detach_Session.sh` | [Detach_Session.md](Detach_Session.md) | Lists all running `screen` sessions, prompts for a session ID, and detaches from it via `screen -X detach` (equivalent to pressing `Ctrl+A d` inside the session). |

## SSH Host Selection

| Script | Doc | Summary |
|---|---|---|
| `Hosts.sh` | [Hosts.md](Hosts.md) | Lets you fuzzy-pick an SSH host alias from `~/.ssh/config` using `fzf`, then connects to it with `ssh`. |

---

## Notes

- `Hosts.sh` is the only script in this folder with Danish console output ("Forbinder til...", "Ingen host valgt.", and the `fzf` header "Vælg SSH host:"); the three `screen`-management scripts use plain English prompts (e.g. "Enter a name for the new session:", "Enter the session ID to detach from:").
- None of the four scripts are destructive — they only start, list, reattach to, or detach from sessions/connections; no files are created or removed.
- `Detach_Session.sh` and `List_Sessions_LogOn.sh` both require the user to already know (or read from the printed `screen -ls` output) the numeric session ID before being prompted — neither offers a numbered menu or search-by-name.
- `Hosts.sh` only reads the second token after `Host` in `~/.ssh/config` (via `awk '{print $2}'`), so a line defining multiple aliases (`Host foo bar`) would only ever offer `foo`; it also has no explicit error if `~/.ssh/config` is missing — it just reports "Ingen host valgt."
