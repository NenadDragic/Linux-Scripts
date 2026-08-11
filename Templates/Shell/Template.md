<!--
TEMPLATE — Shell (.sh) script documentation
How to use this template:
1. Read the target .sh file in full before writing anything.
2. Replace every <angle-bracket> placeholder with real content from the script. Do not invent behavior.
3. Delete this instruction block and any section that doesn't apply (e.g. no Configuration table if the script takes no variables/args).
4. Write in English, even if the script's comments/output are in Danish — note that fact in Notes instead.
5. Keep the section order and heading style exactly as below; this is what Overview.md links to and readers expect consistency.
-->

# <Script Name>

<One short paragraph: what the script does and why it exists. State the actual behavior, not the intent — read the code.>

---

## Usage

```console
chmod +x <ScriptName>.sh
bash <ScriptName>.sh <args>
```

Run it from <describe the expected working directory / input location, e.g. "the folder containing the files to process">.

Prerequisites:

- <Required tools/packages, e.g. exiftool, darktable-cli, jq — note if the script auto-installs them via apt>
- <Required permissions, e.g. must run as a user with write access to the target folder>
- <Any other scripts it depends on being present in the same folder>

### Configuration (top of script)

<Table of variables defined at the top of the script that a user is expected to tweak. Delete this section if there are none.>

| Variable | Default | Meaning |
|---|---|---|
| `<VAR_NAME>` | `<default>` | <what it controls> |

---

## What the Script Does

<Break the actual control flow into numbered steps, mirroring the real order of operations — loops over files, external commands invoked, filters applied, output structure produced.>

### Step 1 – <What happens first>
<Description grounded in the actual code.>

### Step 2 – <Next step>
<Description.>

---

## Notes

<Real edge cases and limitations found by reading the code — not generic caveats. Examples of what belongs here:>

- <Idempotency: is it safe to re-run? does it skip already-processed files?>
- <Destructive behavior: does it move/delete/overwrite files, and under what condition>
- <Performance on large inputs>
- <Environment assumptions, e.g. specific distro/package manager, or non-persistent installs in ephemeral containers/VMs>
- <Language of output messages, if not English>
- <Hardcoded paths or values>
