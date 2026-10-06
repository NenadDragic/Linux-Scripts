#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools git cmake make sudo

# Exit on error
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to remove old versions
remove_old_version() {
    log "Removing old versions of libheif..."
    sudo apt remove --purge -y libheif1 libheif-dev || true
    sudo apt autoremove -y || true
}

# Function to install dependencies
install_dependencies() {
    log "Installing build dependencies..."
    sudo apt update
    sudo apt install -y build-essential cmake pkg-config \
        libaom-dev libx265-dev libjpeg-dev libpng-dev \
        libde265-dev libtool autoconf automake
}

# Function to build and install latest version
build_latest_version() {
    local work_dir="/tmp/libheif-build"
    
    # Remove old build directory if it exists
    if [ -d "$work_dir" ]; then
        rm -rf "$work_dir"
    fi
    
    # Create and enter work directory
    mkdir -p "$work_dir"
    cd "$work_dir"
    
    log "Cloning latest version from GitHub..."
    git clone https://github.com/strukturag/libheif.git .
    
    # Get latest release tag
    git fetch --tags
    latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
    
    log "Checking out latest version: $latest_tag"
    git checkout "$latest_tag"
    
    # Create build directory
    mkdir build
    cd build
    
    log "Configuring build..."
    cmake -DCMAKE_BUILD_TYPE=Release ..
    
    log "Building libheif..."
    make -j$(nproc)
    
    log "Installing libheif..."
    sudo make install
    sudo ldconfig
}

# Function to verify installation
verify_installation() {
    if command -v heif-info &> /dev/null; then
        version=$(heif-info --version)
        log "Successfully installed libheif: $version"
    else
        log "Warning: Installation completed but heif-info command not found"
    fi
}

# Function to cleanup
cleanup() {
    log "Cleaning up build files..."
    rm -rf "/tmp/libheif-build"
}

# Main execution
main() {
    log "Starting libheif update process..."
    
    remove_old_version
    install_dependencies
    build_latest_version
    verify_installation
    cleanup
    
    log "Update process completed successfully!"
}

# Run main function
main
