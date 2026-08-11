<!--
TEMPLATE — Python (.py) script documentation
How to use this template:
1. Read the target .py file in full before writing anything.
2. Replace every <angle-bracket> placeholder with real content from the script. Do not invent behavior.
3. Delete this instruction block and any section that doesn't apply (e.g. no Configuration table if the script takes no args/config).
4. Write in English, even if the script's comments/output are in Danish — note that fact in Notes instead.
5. Keep the section order and heading style exactly as below; this is what Overview.md links to and readers expect consistency.
-->

# <Script Name>

<One short paragraph: what the script does and why it exists. State the actual behavior, not the intent — read the code.>

---

## Usage

```console
python <script_name>.py <args>
```

Prerequisites:

- <Python version, if it matters, e.g. 3.10+>
- <Required packages/dependencies — list them and note if there's a requirements.txt or if they need manual pip install>
- <Any required environment variables, config files, or credentials>

### Configuration / Arguments

<Table of CLI arguments (argparse/click/sys.argv) or top-of-file config constants. Delete this section if the script has neither.>

| Variable/Argument | Default | Meaning |
|---|---|---|
| `<name>` | `<default>` | <what it controls> |

---

## What the Script Does

<Break the actual control flow into numbered steps, mirroring the real order of operations — what it reads, what libraries/APIs it calls, what transformation happens, what it outputs.>

### Step 1 – <What happens first>
<Description grounded in the actual code.>

### Step 2 – <Next step>
<Description.>

---

## Notes

<Real edge cases and limitations found by reading the code — not generic caveats. Examples of what belongs here:>

- <Error handling: what happens on malformed input, missing files, network failures>
- <Performance on large inputs, e.g. loads everything into memory>
- <Side effects: files written/moved/deleted, network calls made>
- <Language of output messages, if not English>
- <Hardcoded paths, credentials, or environment-specific assumptions>
