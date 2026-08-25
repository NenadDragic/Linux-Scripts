# Update_git

Adds, commits, and pushes all pending changes in the current Git repository using a commit message typed in interactively. It exists as a shortcut for the common "stage everything, commit, push" workflow.

---

## Usage

```console
chmod +x Update_git.sh
bash Update_git.sh
```

Run it from inside the working directory of the Git repository you want to update (it operates on the repository of the current directory — it does not `cd` anywhere itself).

Prerequisites:

- `git` installed and the current directory must already be inside a Git repository with a configured remote.
- Push access (credentials/SSH key) to that remote.

---

## What the Script Does

### Step 1 – Prompt for a commit message
The script uses `read -p "Enter commit message: " message` to interactively ask the user for a commit message and stores it in the `message` variable.

### Step 2 – Stage all changes
It runs `git add -A`, staging every new, modified, and deleted file in the repository.

### Step 3 – Commit
It runs `git commit -am "$message"`, committing the staged changes with the message entered in Step 1.

### Step 4 – Push
It runs `git push`, pushing the new commit to the remote/branch already configured for the current repository.

---

## Notes

- Destructive/irreversible by nature: it stages and commits *all* changes in the repository (including deletions) with no confirmation step or diff preview, and then immediately pushes — there is no dry run.
- No check that there are actually changes to commit; running it with a clean working tree will fail at the `git commit` step (nothing to commit) and the script will still attempt `git push` afterward.
- No check that the current directory is a Git repository; if run outside one, `git add -A` and the following commands will simply error out.
- Uses whichever remote and branch are already configured for the current repository — it does not let you choose or specify one.
