# sync-from-github.sh

Scans a base folder for git repositories (one level deep) and, for each one, checks GitHub for new commits and fast-forwards the local checkout — without ever overwriting local, uncommitted work or attempting to resolve a diverged history. Bash equivalent of [Sync-FromGitHub.ps1](Sync-FromGitHub.ps1); see there for the Windows/PowerShell version of the same logic.

---

## Usage

```bash
./sync-from-github.sh
# or, to check a different base folder:
./sync-from-github.sh /path/to/repos
```

Requires `bash` and `git` on the `PATH`. Make it executable once with `chmod +x sync-from-github.sh`, or run it directly with `bash sync-from-github.sh` without changing permissions. Each repo found under the base folder must already have a configured remote-tracking branch (i.e. have been cloned or have `git branch --set-upstream-to` set) — a repo without one is reported and skipped, not treated as an error that stops the rest.

### Configuration

| Value | Default | Meaning |
|---|---|---|
| `$1` (optional argument) | none | Overrides the base folder to scan; if omitted, falls back to the OS-based default below |
| Default base folder | `/h/git` in Git Bash on Windows (`MINGW*`/`MSYS*`/`CYGWIN*`), `$HOME/Git` everywhere else | Folder whose immediate subdirectories are checked for `.git` folders |

---

## What the Script Does

### Step 1 – Pick the base folder
Detects the shell environment via `uname -s`. Under Git Bash/MSYS/Cygwin on Windows it defaults to `/h/git`; on any other `uname` result (Linux, macOS, WSL) it defaults to `$HOME/Git`. If a first argument is given, it overrides this default entirely. Exits with an error if the resulting folder doesn't exist.

### Step 2 – Find repositories
Iterates every immediate subdirectory of the base folder and keeps only the ones containing a `.git` folder — nested repos deeper than one level are not discovered. If none are found, it says so and exits cleanly (not an error).

### Step 3 – Sync each repo in a subshell
For each repo, runs the sync logic inside a `( ... )` subshell so a `cd` or early `exit` in one repo's checks can't affect the others or leak the working directory change to the rest of the script:
1. `git fetch origin --quiet` to update remote-tracking refs.
2. Resolves `local_rev` (`HEAD`), `remote_rev` (`@{u}`), and `base_rev` (their merge-base). If there's no upstream (`remote_rev` empty), it prints a message and moves on to the next repo.
3. **Up to date** (`local_rev == remote_rev`): reports it and does nothing.
4. **Behind** (`local_rev == base_rev`, i.e. fast-forwardable): if `git status --porcelain` shows any local changes, it skips the pull rather than risk clobbering uncommitted work; otherwise it fast-forwards via `git pull --ff-only origin <current-branch>` and prints the newly pulled commits (`git log --oneline`).
5. **Ahead** (`remote_rev == base_rev`): local commits exist that haven't been pushed — reported, nothing pulled.
6. **Diverged** (neither of the above): both sides have unique commits — reported as needing manual merge/rebase; the script never attempts one itself.

### Step 4 – Summary
If the loop never matched any `.git` subdirectory, prints a final "no repos found" message (this only fires when Step 2 found nothing at all, not per-repo).

---

## Notes

- **Only fast-forward pulls are ever performed** (`--ff-only`); the script will never create a merge commit, rebase, or force anything — any situation it can't safely fast-forward is left for the user to resolve by hand.
- **Uncommitted local changes always win** — a repo that's behind but dirty is skipped entirely rather than stashed or overwritten, so re-run the script after committing or stashing to actually pick up the update.
- **Repo discovery is exactly one level deep.** A base folder containing repos nested inside subfolders (e.g. `~/Git/work/some-repo`) won't find `some-repo` — only direct children of the base folder are checked.
- **`set -uo pipefail` is set but not `-e`** — a failing command inside the per-repo subshell (other than the explicit `exit 1` when `cd` fails) does not abort the whole script; the loop continues to the next repo regardless.
- Line endings are forced to LF via the repo's [.gitattributes](../.gitattributes) (`*.sh text eol=lf`) so Windows' `autocrlf` can't corrupt the shebang or `case`/`if` blocks when the file is checked out or touched by git locally.
- Only checks the `origin` remote; a repo with a different or additional remote configured for its upstream branch is not specifically accounted for beyond what `@{u}` already resolves to.
