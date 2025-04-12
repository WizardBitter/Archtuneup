#!/bin/bash

# Set error handling
set -e
trap 'echo -e "\n${RED}Error occurred at line $LINENO. Exit code: $?${NC}" >&2' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Log file setup
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/sysmaintenance.log"

# Ensure log directory exists and is writable
if ! sudo mkdir -p "$LOG_DIR"; then
    echo -e "${RED}Error: Failed to create log directory $LOG_DIR${NC}" >&2
    exit 1
fi

if ! sudo touch "$LOG_FILE" 2>/dev/null; then
    echo -e "${RED}Error: Cannot write to log file $LOG_FILE${NC}" >&2
    exit 1
fi

if ! sudo chown "$USER:$USER" "$LOG_FILE"; then
    echo -e "${RED}Error: Cannot set ownership of log file${NC}" >&2
    exit 1
fi

# Print box with centered text
print_box() {
    local text="$1"
    local color="$2"
    local text_color="$3"
    local text_length=${#text}
    local width=$((text_length + 4))  # Add 4 for the box borders and padding
    local padding=1  # Fixed padding of 1 space on each side
    
    # Create top line
    echo -e "${BOLD}${color}╔$(printf '═%.0s' $(seq 1 $((width-2))))╗${NC}"
    
    # Create text line with padding
    echo -e "${BOLD}${color}║${NC} ${text_color}${text}${NC} ${BOLD}${color}║${NC}"
    
    # Create bottom line
    echo -e "${BOLD}${color}╚$(printf '═%.0s' $(seq 1 $((width-2))))╝${NC}\n"
}

# Print header
print_header() {
    print_box "System Maintenance Script" "$BLUE" "$CYAN"
}

# Print section header
print_section() {
    echo -e "\n${BOLD}${YELLOW}▶ ${1}${NC}"
    echo -e "${DIM}${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}! ${1}${NC}"
}

# Print info message
print_info() {
    echo -e "${CYAN}ℹ ${1}${NC}"
}

# Logging function
log() {
    if ! echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"; then
        print_error "Failed to write to log file"
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed"
        exit 1
    fi
}

# Function to get user confirmation
confirm() {
    read -r -p "${YELLOW}$1 [y/N]${NC} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Print header
print_header

# Check required commands
print_section "Checking Requirements"
check_command paru
check_command paccache
check_command journalctl
print_success "All required commands are available"

# System update
print_section "System Update"
log "Starting system maintenance"
if ! paru -Syu; then
    print_error "System update failed"
    log "Error: System update failed"
    exit 1
fi
print_success "System updated successfully"

# Clear pacman cache
print_section "Cache Maintenance"
log "Clearing pacman cache"
pacman_cache_space_used="$(du -sh /var/cache/pacman/pkg/)"
if ! paccache -r; then
    print_error "Failed to clear pacman cache"
    log "Error: Failed to clear pacman cache"
    exit 1
fi
print_success "Pacman cache cleared"
print_info "Space saved: $pacman_cache_space_used"

# Remove orphan packages
print_section "Package Maintenance"
log "Checking for orphan packages"
orphans=$(paru -Qdtq || true)
if [ -n "$orphans" ]; then
    print_warning "Found orphan packages:"
    echo -e "${DIM}$orphans${NC}"
    if confirm "Do you want to remove these orphan packages?"; then
        if ! paru -Qdtq | paru -Rns -; then
            print_error "Failed to remove orphan packages"
            log "Error: Failed to remove orphan packages"
            exit 1
        fi
        print_success "Successfully removed orphan packages"
        log "Successfully removed orphan packages"
    else
        print_info "Skipped orphan package removal"
        log "Skipped orphan package removal"
    fi
else
    print_success "No orphan packages found"
    log "No orphan packages found"
fi

# Clear home cache
print_section "Home Cache Maintenance"
log "Clearing ~/.cache"
home_cache_used="$(du -sh ~/.cache)"
if confirm "Do you want to clear ~/.cache? This will remove all cached files."; then
    if ! rm -rf ~/.cache/*; then
        print_error "Failed to clear home cache"
        log "Error: Failed to clear home cache"
        exit 1
    fi
    print_success "Home cache cleared"
    print_info "Space saved: $home_cache_used"
    log "Space saved: $home_cache_used"
else
    print_info "Skipped clearing home cache"
    log "Skipped clearing home cache"
fi

# Clear system logs
print_section "System Logs Maintenance"
log "Clearing system logs older than 7 days"
if ! sudo journalctl --vacuum-time=7d; then
    print_warning "Some system logs could not be cleared (permission denied)"
    log "Warning: Some system logs could not be cleared (permission denied)"
    # Don't exit here as this is not critical
else
    print_success "System logs cleaned successfully"
fi

# Print footer
print_box "System maintenance completed successfully" "$BLUE" "$GREEN"

log "System maintenance completed successfully"
sleep 2