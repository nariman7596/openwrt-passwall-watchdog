#!/bin/sh

INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/passwall_watchdog"
HOTPLUG_FILE="/etc/hotplug.d/button/99-passwall-watchdog"
INIT_FILE="/etc/init.d/passwall_watchdog"
SCRIPT_NAME="Passwall_watchdog.sh"
PID_FILE="/tmp/passwall_watchdog.pid"
LOCK_FILE="/tmp/passwall_watchdog.lock"

info()    { echo "  $1"; }
success() { echo "  [OK] $1"; }
warn()    { echo "  [!!] $1"; }
ask()     { printf "  >>> %s: " "$1" >&2; read -r REPLY; echo "$REPLY"; }

echo ""
echo "========================================"
echo "   Passwall Watchdog Uninstaller"
echo "========================================"
echo ""

# --- Stop the running service ---
if [ -f "$INIT_FILE" ]; then
    "$INIT_FILE" stop > /dev/null 2>&1
    "$INIT_FILE" disable > /dev/null 2>&1
    rm -f "$INIT_FILE"
    success "Service stopped and removed"
else
    warn "Init script not found, skipping service removal"
fi

# --- Clean up runtime files ---
rm -f "$PID_FILE" "$LOCK_FILE"

# --- Remove hotplug trigger ---
if [ -f "$HOTPLUG_FILE" ]; then
    rm -f "$HOTPLUG_FILE"
    success "Hotplug trigger removed"
fi

# --- Remove main script ---
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    success "Main script removed"
fi

# --- Ask about config and backups ---
if [ -d "$CONFIG_DIR" ]; then
    KEEP=$(ask "Keep config and backups in $CONFIG_DIR? (y/n) [y]")
    if [ "$KEEP" = "n" ] || [ "$KEEP" = "N" ]; then
        rm -rf "$CONFIG_DIR"
        success "Config and backups removed"
    else
        success "Config and backups kept at $CONFIG_DIR"
    fi
fi

echo ""
echo "========================================"
success "Uninstall complete."
info "Passwall2 itself was not modified or removed."
echo "========================================"
echo ""
