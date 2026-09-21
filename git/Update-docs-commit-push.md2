# update-docs-commit-push.sh

Calls the Claude Code CLI with a fixed prompt that finds script files of any language (`.ps1`, `.sh`, `.py`, etc.) anywhere in the repo missing a matching `.md` doc, writes that documentation in the same style as the existing docs, updates the relevant overview file (the root [Overview.md](../Overview.md), or [Tools/README.md](README.md) for scripts under `Tools/`), and then commits and pushes the result to `origin` — all without asking for confirmation along the way. Bash equivalent of [Update-Docs-Commit-Push.ps1](Update-Docs-Commit-Push.ps1); see there for the Windows/PowerShell version of the same logic.

---

## Usage

```bash
./update-docs-commit-push.sh
```

Requires `bash`, `git`, and the [Claude Code CLI](https://claude.com/claude-code) (`claude`) on the `PATH`, logged in on the machine that runs it. Make it executable once with `chmod +x update-docs-commit-push.sh`, or run it directly with `bash update-docs-commit-push.sh`. It takes no arguments or configuration — the prompt sent to Claude is fixed in the script.

---

## What the Script Does

### Step 1 – Locate the repo and verify prerequisites
Resolves the repo root via `git rev-parse --show-toplevel` and `cd`s into it, exiting with an error if the current directory isn't inside a git repo. Checks that `claude` is on the `PATH` via `command -v claude`, exiting with an error and no further action if it isn't.

### Step 2 – Build the prompt
Assembles a fixed, multi-line Danish prompt (via a heredoc) instructing Claude to: find script files of any language, anywhere in the repo (all folders/subfolders, excluding `.git`), without a matching `.md`; read a couple of existing `.md` files (e.g. in `PowerShell/`) to match their structure (title/summary, Usage, Configuration table, "What the Script Does" steps, Notes); write new docs based only on what each script's code actually does; skip — rather than guess at, rename, or move — any script that's empty, whose content clearly doesn't match its filename, or whose file extension doesn't match the language it's actually written in (e.g. a `.py` file containing PowerShell code), explaining the situation in the final summary instead; update the right overview file with each new/fixed script in the right section (`Tools/README.md` for scripts under `Tools/`, the root `Overview.md` under the matching language heading for everything else); stage only the relevant files (not `git add -A`/`git add .`); make one commit and push to `origin`; and finish with a short summary of what was committed versus skipped. If nothing is missing documentation, it's told to say so and make no commit.

### Step 3 – Run Claude Code non-interactively
Invokes `claude -p "$prompt" --permission-mode acceptEdits --allowedTools "Read Write Edit Glob Grep Bash(git *)"`. `-p` runs it print-mode/non-interactive (no back-and-forth), `--permission-mode acceptEdits` auto-accepts file edits without prompting, and `--allowedTools` restricts what it can do to reading/writing files and running `git` commands — it cannot invoke arbitrary shell commands or other tools.

---

## Notes

- **This script pushes to `origin` automatically, with no confirmation step.** Only run it when you're fine with new commits landing on GitHub unattended — Claude decides on its own what counts as "documentation is missing" and what commit message to use.
- **The `Bash(git *)` tool restriction only limits which command Claude can run, not what it does with it** — it can still run `git push --force` or similar if it decides to, since any `git` subcommand matches the wildcard. The prompt only asks for a plain commit + push; it doesn't technically prevent more.
- **Skips rather than fabricates.** The prompt explicitly tells Claude to leave a script undocumented (and explain why) rather than invent behavior for an empty or filename-inconsistent script — this was added after exactly that situation came up with a real script in this repo.
- Every run re-sends the full fixed prompt and re-scans the whole repo — there's no state tracking which scripts were already checked, so it's safe (if slightly redundant) to run repeatedly.
- No output is captured or logged beyond what `claude -p` prints to the terminal — there's no separate log file to review after the fact.
