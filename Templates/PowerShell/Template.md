<!--
TEMPLATE — PowerShell (.ps1) script documentation
How to use this template:
1. Read the target .ps1 file in full before writing anything.
2. Replace every <angle-bracket> placeholder with real content from the script. Do not invent behavior.
3. Delete this instruction block and any section that doesn't apply (e.g. no Parameters table if the script has none).
4. Write in English, even if the script's comments/output/variable names are in Danish — note that fact in Notes instead.
5. Keep the section order and heading style exactly as below; this is what Overview.md links to and readers expect consistency.
-->

# <Script Name>

<One short paragraph: what the script does and why it exists. State the actual behavior, not the intent — read the code.>

---

## Usage

```powershell
.\<ScriptName>.ps1 -<Param> <value>
```

Prerequisites:

- <Required modules, e.g. ActiveDirectory (RSAT), ImportExcel, PSWindowsUpdate>
- <Required rights, e.g. local admin, Domain Admin, delegated log-read rights on DCs>
- <Remoting requirements, e.g. WinRM reachable on target machines>
- <Execution policy note, e.g. run via `powershell -ExecutionPolicy Bypass -File .\Script.ps1` if unsigned>

### Configuration / Parameters

<Table of either `param()` block arguments or hardcoded config variables at the top of the script. Delete this section if the script has neither.>

| Variable/Parameter | Default | Meaning |
|---|---|---|
| `<$Name>` | `<default>` | <what it controls> |

---

## What the Script Does

<Break the actual control flow into numbered steps. Mirror the real order of operations in the script — loops, remote calls, filters, classification logic, output generation. Name real cmdlets/APIs used (e.g. `Get-WinEvent`, `Invoke-Command`, `Get-ADDomainController`).>

### Step 1 – <What happens first>
<Description grounded in the actual code.>

### Step 2 – <Next step>
<Description.>

---

## Notes

<Real edge cases and limitations found by reading the code — not generic caveats. Examples of what belongs here:>

- <Performance impact at scale, e.g. querying every DC / large drives>
- <Error handling behavior, e.g. unreachable machines are logged but don't abort the run>
- <Output file location/format and naming/timestamp scheme>
- <Language of console output / log messages, if not English>
- <Hardcoded values: paths, thresholds, account names, credentials/secrets — flag presence of secrets without reproducing the value>
- <Anything the script's name implies that it does NOT actually do, if misleading>
