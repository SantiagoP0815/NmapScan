# nmapscan

Bash wrapper for Nmap that automates two-phase network reconnaissance: fast port discovery followed by a detailed service/version scan on found ports only.

## Usage

```bash
sudo nmapscan <IP> [options]
```

## Options

| Flag | Description |
|---|---|
| `-o DIR` | Output directory (default: `./Scan`) |
| `-r RATE` | Min-rate for phase 1 (default: 5000, use `0` to disable) |
| `-p PORTS` | Skip phase 1, scan these ports directly (e.g. `80,443,5985`) |
| `-s` | Slow mode: no `--min-rate`, adds `-T2` (bypasses rate-limiting firewalls) |
| `-u` | Also run UDP scan on top 200 ports (requires root) |
| `-6` | Scan IPv6 target |
| `--no-syn` | Use `-sT` (connect scan) instead of `-sS` — does not require root |

## How it works

**Phase 1 — Port discovery**

Scans all 65535 TCP ports with `--min-rate 5000` to quickly find open ports.

```bash
nmap -p- --open -sS --min-rate 5000 -n -Pn <IP>
```

**Phase 2 — Detailed scan**

Runs `-sCV` (service versions + default NSE scripts) only on the ports found in phase 1.

```bash
nmap -p<open_ports> -sCV -Pn <IP>
```

**Phase 3 (optional) — UDP scan**

Top 200 UDP ports when `-u` flag is set.

## Output

Results are saved with timestamps to avoid overwriting previous scans:

```
Scan/
├── allports_10.10.10.1_20260607_143022.txt   # Phase 1 output
├── fullscan_10.10.10.1_20260607_143022.txt   # Phase 2 output
└── udpscan_10.10.10.1_20260607_143022.txt    # UDP scan (if -u)
```

## Installation

```bash
sudo cp nmapscan.sh /usr/local/bin/nmapscan
sudo chmod +x /usr/local/bin/nmapscan
```

## Examples

```bash
# Standard scan
sudo nmapscan 10.10.10.1

# Save to custom directory
sudo nmapscan 10.10.10.1 -o ./results

# Skip phase 1, scan specific ports
sudo nmapscan 10.10.10.1 -p 22,80,443

# Slow mode for firewalled targets
sudo nmapscan 10.10.10.1 -s

# Full scan with UDP
sudo nmapscan 10.10.10.1 -u
```

## Requirements

- `nmap`
- Root/sudo (for `-sS` SYN scan; use `--no-syn` to avoid)
