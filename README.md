# Arch Linux System Maintenance Script

A comprehensive bash script for maintaining and optimizing Arch Linux systems.

## Features

- System updates (`paru -Syu`)
- Pacman cache cleanup (`paccache -r`)
- Orphan package removal
- Home directory cache cleanup
- System log rotation (`journalctl --vacuum-time=7d`)
- Colorful terminal output with status indicators
- Comprehensive logging to [/var/log/sysmaintenance.log](cci:7://file:///var/log/sysmaintenance.log:0:0-0:0)
- Interactive confirmation prompts for critical operations
- Error handling and logging

## Requirements

- Arch Linux (or Arch-based distribution)
- `paru` AUR helper
- `paccache` (part of `pacman-contrib` package)
- `journalctl` (part of `systemd`)

## Installation

1. Clone this repository or download the script:
   ```bash
   git clone https://github.com/WizardBitter/Archtuneup.git
   cd Archtuneup
   chmod +x archtuneup.sh
   ./archtuneup.sh
