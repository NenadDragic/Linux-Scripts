# Hosts Script

Lets you fuzzy-pick an SSH host alias from `~/.ssh/config` using `fzf`, then connects to it with `ssh`.

---

## Usage

```console
chmod +x Hosts.sh
bash Hosts.sh
```

Run it from anywhere — it takes no arguments and reads `~/.ssh/config` directly.

Prerequisites:

- `fzf` installed
- `grep`, `awk`, `sort`, `ssh` (standard tools)
- A `~/.ssh/config` file containing `Host` entries

---

## What the Script Does

### Step 1 – Build and present the host list
`grep -i "^Host " ~/.ssh/config` pulls out lines starting with `Host `, `grep -v "*"` filters out wildcard entries (e.g. `Host *`), `awk '{print $2}'` extracts the alias, and `sort -f` sorts the list case-insensitively. The result is piped into `fzf --height 40% --reverse --border --header="Vælg SSH host:"` for interactive selection, and the chosen value is stored in `$target`.

### Step 2 – Connect, or report nothing chosen
If `$target` is non-empty, it prints "Forbinder til $target..." and runs `ssh "$target"`. If the user pressed Esc / selected nothing, it prints "Ingen host valgt." instead.

---

## Notes

- Output messages are in Danish ("Forbinder til...", "Ingen host valgt.").
- Only the first token after `Host` is picked up (via `awk '{print $2}'`); a `Host` line defining multiple aliases (`Host foo bar`) would only ever offer `foo`.
- If `~/.ssh/config` is missing or has no `Host` lines, `grep` simply returns nothing, `$target` stays empty, and the script reports "Ingen host valgt." — no explicit file-not-found error.
- Not destructive; it only launches an interactive `ssh` session to the chosen host.
