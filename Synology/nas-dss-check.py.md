# nas-dss-check Python Script

Reads the Task Scheduler scripts out of a Synology DSM configuration export (`.dss`), compares each one with the scripts kept in git, shows the lines that differ, runs a syntax check and `shellcheck` on them, and searches both the DSM scripts and git for secrets. It exists to show whether the NAS and the repository have drifted apart, and to catch credentials before they are committed.

---

## Usage

```console
python3 nas-dss-check.py ~/Downloads/Dragic_20261009.dss ~/git/Devices/NAS/Synology
python3 nas-dss-check.py DSS GITDIR --scan ~/git/Devices       # search the whole repository for secrets
python3 nas-dss-check.py DSS GITDIR --export /tmp/nas-export   # write the DSM scripts out as files
python3 nas-dss-check.py DSS GITDIR --context 3                # show 3 unchanged lines around each difference
python3 nas-dss-check.py DSS GITDIR --no-diff                  # leave out the differences
```

Normally run through the wrapper [nas-dss-check.sh](nas-dss-check.md), which picks the newest export and fills in the folders.

Prerequisites:

- Python 3 (standard library only, no `pip` packages)
- `bash` — used for the syntax check (`bash -n`)
- `shellcheck` is optional; without it the lint part of section 3 is skipped and a note is printed
- A `.dss` export from DSM and a folder with the NAS scripts in git
- No `sudo`: the script only reads the export and the git folder, and writes to a temporary folder (and to `--export DIR` when given)

### Configuration / Arguments

| Variable/Argument | Default | Meaning |
| --- | --- | --- |
| `dss` | required | The DSM configuration export to read. |
| `gitdir` | required | Folder with the scripts in git that the DSM tasks are compared against. Subfolders are included. |
| `--scan DIR` | none | Also search `DIR` for secrets. Can be repeated. |
| `--export DIR` | off | Write each DSM script to `DIR` as `<task name>.sh`. |
| `--no-shellcheck` | off | Skip `shellcheck` even when it is installed. |
| `--no-diff` | off | Do not show the differences (section 2). |
| `--context N` | `0` | Number of unchanged lines shown around each difference. `0` shows only the changed lines. |
| `SC_EXCLUDE` | `SC2209,SC2054` | Constant at the top of the file: `shellcheck` findings that are intentional in the NAS scripts. |
| `SECRET_PATTERNS` | 6 patterns | Constant at the top of the file: the regular expressions that count as a secret. |

---

## What the Script Does

### Step 1 – Read the git folder

Walks `gitdir` (skipping `.git`) and loads every `.sh`, `.md` and `.txt` file. Only the `.sh` files are used for the comparison.

### Step 2 – Read the tasks from the export

Opens the `.dss` as a tar archive, extracts only the `_Syno_ConfBkp.db` SQLite database into a temporary folder, and reads the tasks from `confbkp_scheduler_table` and the user names from `confbkp_user_tb`. Each task's command is base64-decoded when it is base64. Tasks that are not user-defined scripts are marked as built-in DSM tasks.

### Step 3 – Compare each task with git (section 1)

Prints one line per task with its id, name, state, owner and schedule, followed by one of:

| Result | Meaning |
| --- | --- |
| `IDENTISK med <file>` | The script matches a git file exactly, ignoring line endings and trailing whitespace. |
| `samme kode som <file>` | Only comments differ. |
| `AFVIGER fra <file>` | Differs from the closest git file. Shows the similarity, both version numbers and which side is newer. Counts as a problem. |
| `MANGLER i git` | No git file has the task's name or is at least 60 % similar. Counts as a problem. |
| `indbygget DSM-opgave` | Built-in DSM task with no script; skipped. |

The closest file is the one named after the task (outside `Old/`), otherwise the most similar one. Git scripts outside `Old/` that no task uses are listed afterwards as candidates for `Old/`; this list does not count as a problem.

### Step 4 – Show the differences (section 2)

For every task that has a git counterpart but is not identical to it (`samme kode` or `AFVIGER`), prints a unified diff with the git file as `-` and the NAS script as `+`. With the default `--context 0` only the changed lines are shown, each group headed by an `@@ -git +NAS @@` line with the line numbers. Line endings and trailing whitespace are ignored, so only real changes show up. Secrets in the diff lines are masked with the same patterns as section 4. Colours (red, green, cyan) are used only when the output is a terminal and `NO_COLOR` is not set. Showing a difference does not count as a problem; the status line in section 1 already does.

### Step 5 – Syntax and lint (section 3)

Writes each task's script to the temporary folder and runs `bash -n` on it. When `shellcheck` is available it also runs with severity `warning` and the `SC_EXCLUDE` exclusions, showing at most the first three findings per task. A syntax error or any `shellcheck` finding counts as a problem.

### Step 6 – Search for secrets (section 4)

Checks every line of the DSM scripts, and of the `.sh`, `.md`, `.txt`, `.conf`, `.py`, `.yml`, `.yaml` and `.json` files in `gitdir` and each `--scan` folder, against `SECRET_PATTERNS`: API keys in URLs, cPanel webcall tokens, passwords given to `sshpass` on the command line, clear-text passwords, tokens/secrets and private keys. Each hit is printed with file, line number and type, with the value masked to its first three characters. Every hit counts as a problem.

### Step 7 – Export (only with `--export`)

Creates `DIR` and writes one `<task name>.sh` per task name with LF line endings. When several tasks share a name, the one with the highest version wins, then an enabled task over a disabled one, then the highest id; the others are listed as not exported. A script that contains a secret is skipped.

### Step 8 – Result

Prints `Resultat: alt i orden` and exits with `0` when nothing was found, otherwise the number of points and exit code `1`.

---

## Notes

- Comments and console output are in Danish.
- Read-only unless `--export` is used. The database is extracted to a temporary folder that is deleted when the script ends.
- `--export` overwrites existing files of the same name in `DIR` without asking.
- Needs no root rights and should not be run with `sudo`; files written by `--export` would then be owned by root.
- Commented-out lines are searched for secrets too, since a value in a comment is just as visible in git.
- The secret search is pattern-based: it can report harmless lines (for example `password=` followed by a placeholder) and miss secrets in other formats. Files with other extensions are not searched.
- Version 1.1 rewords the description of the `sshpass` pattern, so the script no longer reports itself when its own folder is scanned.
- No diff is shown for identical tasks or for tasks that are missing in git, since there is nothing to compare.
- A missing or wrongly formatted export stops the script: without `_Syno_ConfBkp.db` it exits with `FEJL: ...`, and a file that is not a tar archive ends in a Python traceback.
- The version comparison reads the first `# Version:` line of each script; a script without one counts as version 0.
- The table and field names come from one DSM export format and may change with a DSM update.
