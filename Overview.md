# Linux-Scripts Repository Overview

Root index of every documented folder in this repository. Each folder listed below has its own `Overview.md` indexing the scripts inside it; each script has a matching `.md` file describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Scripts

General-purpose Linux admin/utility scripts, grouped by topic.

| Folder | Overview | Scripts | What's there |
| --- | --- | --- | --- |
| `Backup` | [Overview](Backup/Overview.md) | 10 | Rsync-based backups (NAS/USB/SD), archiving of dated backup folders, NAS-share copy to an encrypted WD drive, mount/status/unmount helper for that drive, raw `dd` disk imaging, per-user crontab backups, plus USB mount management. |
| `Create_PDF_From_Web` | [Overview](Create_PDF_From_Web/Overview.md) | 1 | Converts a list of URLs into dated PDFs via `wkhtmltopdf`. |
| `File_Handle` | [Overview](File_Handle/Overview.md) | 14 | File discovery, archiving (7z), renaming, SMB share mounting, real-time disk-usage monitoring, and test-data generation. |
| `IBM` | [Overview](IBM/Overview.md) | 1 | IBM server hardware/firmware info menu. |
| `Install` | [Overview](Install/Overview.md) | 2 | Driver/monitor-mode setup for the AWUS036ACH Wi-Fi adapter, plus an interactive apt tool-picker. |
| `Network` | [Overview](Network/Overview.md) | 1 | WireGuard VPN up/down/status wrapper. |
| `Pic` | [Overview](Pic/Overview.md) | 9 | Photo/video sorting by date and camera model, HEIC/DNG conversion, playback, and library maintenance. |
| `Screen` | [Overview](Screen/Overview.md) | 4 | GNU `screen` session helpers, plus an SSH host picker. |
| `Tmux` | [Overview](Tmux/Overview.md) | 1 | Rotates a tmux client between selected sessions for a dashboard screen. |
| `Updates` | [Overview](Updates/Overview.md) | 8 | System/package/firmware update scripts across different distros and apps. |
| `git` | [Overview](git/Overview.md) | 6 | Bulk git maintenance (init/pull/status/commit/sync) across local repos, plus Claude Code-driven doc updates. |

## Support

| Folder | Overview | What's there |
| --- | --- | --- |
| `lib` | [Overview](lib/Overview.md) | `require_tools.sh`, the shared dependency checker that scripts source at startup. |
| `Templates` | [Overview](Templates/Overview.md) | Documentation templates (Overview, Shell, PowerShell, Python) used to write the `.md` files. |

---

## Notes

- Every `.sh` script has a matching `.md` file; see [Templates/](Templates/) for the templates used to write them.
- Scripts that use tools beyond the standard base system start with a dependency-check block that sources [lib/require_tools.sh](lib/require_tools.sh); scripts that only use standard tools have no such block.
- Several scripts print console output/comments in Danish even though all documentation is written in English — each affected script's own `.md` flags this individually.
