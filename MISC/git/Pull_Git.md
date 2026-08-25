# Pull_Git

Runs `git pull` in every Git repository found directly under `~/git`. It exists to update all of NenadDragic's locally cloned repositories in one pass, without having to `cd` into each one manually.

---

## Usage

```console
chmod +x Pull_Git.sh
bash Pull_Git.sh
```

Run it from anywhere; it does not use the directory it is launched from — it operates on the fixed `~/git` folder (see Configuration below).

Prerequisites:

- `git`, with any credentials/SSH keys already configured for the remotes of the repositories under `~/git`.
- Read/write access to `~/git` and to each repository inside it (a `git pull` may need to write to the working tree).

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `base_dir` | `~/git` | The directory whose immediate subdirectories are scanned for Git repositories to pull. |

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

### Step 5 – Pull and report
For each directory that is a Git repository, it prints `Running git pull in $dir` and then runs `git pull`, using whatever remote/branch tracking is already configured for that repository.

---

## Notes

- `cd "$dir"` changes the shell's working directory on every iteration but the directory is never restored (no `cd -` / pushd-popd), though this has no practical effect since the loop always re-derives `dir` from `base_dir` via the glob.
- No merge-conflict handling: if a `git pull` results in a conflict or diverged history, the script does not detect or report it specially — the raw output/error from `git pull` is simply printed and the loop continues to the next directory.
- Only scans one level deep under `base_dir`; a Git repository nested inside a non-repository folder under `~/git` would not be found.
- Assumes the `~/git` layout used by the author's other scripts (`Init_Git.sh`, `Status_Git.sh`) — change `base_dir` if repositories are stored elsewhere.
