# Network Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## VPN Management

| Script | Doc | Summary |
|---|---|---|
| `VPN.sh` | [VPN.md](VPN.md) | A thin wrapper around `wg-quick` and `wg` that brings a WireGuard interface up, shows its status, or tears it down, via three subcommands (`up`, `show`, `down`). |

---

## Notes

- Output messages (usage line, invalid-command errors) are in Danish.
- Destructive/risky: `up` and `down` change live network/VPN state and require root privileges via `sudo`, with no confirmation prompt.
- Does not validate that the given interface name actually corresponds to an existing WireGuard config; `wg-quick` reports its own error if it doesn't.
