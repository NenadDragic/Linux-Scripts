# Status_Git

Runs `git status` in every Git repository found directly under `~/git`. It exists to give a quick overview of the working-tree state (uncommitted changes, ahead/behind remote, etc.) across all of NenadDragic's locally cloned repositories at once.

---

## Usage

```console
chmod +x Status_Git.sh
bash Status_Git.sh
```

Run it from anywhere; it does not use the directory it is launched from — it operates on the fixed `~/git` folder (see Configuration below).

Prerequisites:

- `git` installed.
- Read access to `~/git` and to each repository inside it.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `base_dir` | `~/git` | The directory whose immediate subdirectories are scanned for Git repositories to check. |

---

## What the Script Does

### Step 1 – Clear the terminal
The script starts with `clear`, wiping the terminal screen before printing any output.

### Step 2 – Iterate over each entry in `~/git`
It loops over every entry directly inside `base_dir` (`~/git` by default).

### Step 3 – Filter to directories only
For each entry, it checks `[ -d "$dir" ]` and skips anything that isn't a directory.

### Step 4 – Filter to Git repositories
It `cd`s into the directory and checks whether it contains a `.git` subdirectory; non-Git directories are skipped.

### Step 5 – Print status
For each directory that is a Git repository, it prints `Running git status in $dir`, runs `git status`, and then prints a blank line as a separator before moving to the next repository.

---

## Notes

- Read-only: `git status` makes no changes, so this script is always safe to re-run.
- Only scans one level deep under `base_dir`; a Git repository nested inside a non-repository folder under `~/git` would not be found.
- `cd "$dir"` changes the shell's working directory on every iteration but it is never restored afterward; this has no practical effect here since the loop re-derives `dir` from `base_dir` each time.
- Companion script to `Pull_Git.sh` and `Init_Git.sh`; assumes the same `~/git` layout. Change `base_dir` if repositories are stored elsewhere.
