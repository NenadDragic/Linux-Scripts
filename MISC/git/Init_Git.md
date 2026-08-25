# Init_Git

Clones every one of NenadDragic's GitHub repositories, one `git clone` per repository, into the current working directory. It exists as a one-shot way to set up a fresh machine with all of the author's repos already checked out.

---

## Usage

```console
chmod +x Init_Git.sh
bash Init_Git.sh
```

Run it from the parent folder under which you want all the repositories to be cloned (e.g. `~/git`) — each repository is cloned into a new subfolder named after it, created in the current directory.

Prerequisites:

- `git`, with SSH access configured for GitHub (all clone URLs use the `git@github.com:...` SSH form, so a working SSH key registered with the `NenadDragic` GitHub account is required).
- Write permission in the current directory.
- Network access to GitHub.

---

## What the Script Does

### Step 1 – Clone each repository in a fixed list

The script runs one `git clone` per repository, back to back, with no looping or configuration — the list of repositories is hardcoded in the script itself:

- `Bash`, `bat`, `c-Sharp`, `cpp`, `Cyber-Sec`, `Devices`, `Edora`, `JB-Scripts`, `Learning`, `Linux_Learning`, `Linux-Scripts`, `PowerShell`, `Python`, `RaspberryPi`, `Web-Source`, `Web_source`, `z-os`, `z-os_JB`

Each is cloned from `git@github.com:NenadDragic/<repo>.git` into a subdirectory of the same name under the current directory.

---

## Notes

- Not idempotent: `git clone` fails (and prints an error) for any repository that already exists as a directory in the current path, but the script keeps running the remaining `git clone` commands regardless — it does not check for existing folders or `git pull` instead.
- The repository list is hardcoded; adding, renaming, or removing one of NenadDragic's GitHub repos requires editing the script directly, there is no configuration variable.
- All clone URLs use SSH (`git@github.com:...`), not HTTPS, so it will fail outright on a machine without an SSH key registered to the `NenadDragic` GitHub account.
- No error handling: if one clone fails (e.g. no network, repo renamed/deleted), the script does not stop or report a summary — it just continues to the next `git clone`.
