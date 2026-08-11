# git Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Git Repository Maintenance

| Script | Doc | Summary |
|---|---|---|
| `Init_Git.sh` | [Init_Git.md](Init_Git.md) | Clones all of NenadDragic's GitHub repositories (a fixed list of 14 named repos) to the current directory. |
| `Pull_Git.sh` | [Pull_Git.md](Pull_Git.md) | Iterates through every subdirectory under the `~/git` base directory, and for each one that is a Git repository, runs `git pull` to fetch and integrate remote changes. |
| `Status_Git.sh` | [Status_Git.md](Status_Git.md) | Iterates through every subdirectory under a user-defined base directory (default `~/git`), and for each one that is a Git repository, runs `git status` to show its state. |
| `Update_git.sh` | [Update_git.md](Update_git.md) | Prompts for a commit message, then runs `git add -A`, `git commit -am`, and `git push` to add, commit, and push all changes in the current repository. |

---

## Notes

- All four scripts operate over a fixed list or fixed base directory that is specific to the original author's setup: `Init_Git.sh` hardcodes a list of 14 repositories under the `NenadDragic` GitHub account, while `Pull_Git.sh` and `Status_Git.sh` default to iterating `~/git` — these need editing (repo list or `base_dir`) before reuse on another machine or account.
- `Init_Git.sh` clones into whatever directory it's run from, while `Pull_Git.sh`/`Status_Git.sh` expect repos to already live under `~/git` — if `Init_Git.sh` is run somewhere other than `~/git`, the other two scripts won't find the cloned repos.
- `Update_git.sh` is the only script here that changes remote state (it pushes commits); `Pull_Git.sh` changes local working trees via `git pull`; `Status_Git.sh` is read-only.
- This folder also contains `GIT_compare_lokal_vs_github.md`, a standalone cheatsheet of `git fetch`/`log`/`diff` comparison commands (in Danish) with **no corresponding `.sh` script** — it documents a manual workflow rather than an executable script, so it is intentionally left out of the table above.
