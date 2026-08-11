# VPN Script

A thin wrapper around `wg-quick` and `wg` that brings a WireGuard interface up, shows its status, or tears it down, via three subcommands.

---

## Usage

```console
chmod +x VPN.sh
bash VPN.sh <command> <interface>
```

Example straight from the script's own error message: `sudo sh VPN.sh up Dragic`

Prerequisites:

- WireGuard tools installed (`wg-quick`, `wg`)
- `sudo` access — every branch invokes `sudo wg-quick ...` or `sudo wg ...`
- A valid WireGuard interface/config name that `wg-quick` recognizes (e.g. matching `/etc/wireguard/<INTERFACE>.conf`)

---

## What the Script Does

### Step 1 – Validate argument count
Checks `[ "$#" -lt 2 ]`; if fewer than 2 arguments were passed, prints a Danish usage line (`Brug: $0 ...`) and exits with status `1`.

### Step 2 – Parse arguments
`COMMAND=$1` and `INTERFACE=$2` capture the subcommand and the target WireGuard interface name.

### Step 3 – Dispatch on command
A `case "$COMMAND"` statement:

- `up` → `sudo wg-quick up "$INTERFACE"`
- `show` → `sudo wg show "$INTERFACE"`
- `down` → `sudo wg-quick down "$INTERFACE"`
- anything else → prints "Ugyldig kommando: $COMMAND", lists the valid commands (up, show, down), shows the usage example, and exits with status `1`

---

## Notes

- Output messages are in Danish ("Brug", "Ugyldig kommando", "Gyldige kommandoer er").
- Destructive/risky: `up` and `down` change live network/VPN state and require root privileges; there is no confirmation prompt.
- No validation that `$INTERFACE` actually exists as a WireGuard config — `wg-quick` will error out on its own if it doesn't.
- Re-running `up` on an already-up interface (or `down` on an already-down one) is handled by `wg-quick`'s own behavior, not by any logic in this script.
- The interface name `Dragic` appears only inside the usage/error example text, not as a functional default.
