#!/bin/sh
# --- Paths (must match install.sh) ---
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/passwall_watchdog"
HOTPLUG_FILE="/etc/hotplug.d/button/99-passwall-watchdog"
INIT_FILE="/etc/init.d/passwall_watchdog"
SCRIPT_NAME="Passwall_watchdog.sh"
PID_FILE="/tmp/passwall_watchdog.pid"

# --- Helpers ---
info()    { echo "  $1"; }
success() { echo "  [OK] $1"; }
warn()    { echo "  [!!] $1"; }
ask()     { printf "  >>> %s: " "$1"; read -r REPLY; echo "$REPLY"; }

echo ""
echo "========================================"
echo "   Passwall Watchdog Uninstaller"
echo "========================================"
echo ""

# --- Step 1: Stop and disable service ---
if [ -f "$INIT_FILE" ]; then
    "$INIT_FILE" stop 2>/dev/null
    "$INIT_FILE" disable 2>/dev/null
    rm -f "$INIT_FILE"
    success "Service stopped, disabled, and removed"
else
    warn "Init service not found, skipping"
fi

# --- Step 2: Kill any running watchdog instance ---
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null)
    [ -n "$old_pid" ] && kill -9 "$old_pid" 2>/dev/null
    rm -f "$PID_FILE"
    success "Running watchdog process stopped"
fi

# --- Step 3: Remove hotplug trigger ---
if [ -f "$HOTPLUG_FILE" ]; then
    rm -f "$HOTPLUG_FILE"
    success "Hotplug trigger removed: $HOTPLUG_FILE"
else
    warn "Hotplug trigger not found, skipping"
fi

# --- Step 4: Remove main script ---
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    success "Main script removed: $INSTALL_DIR/$SCRIPT_NAME"
else
    warn "Main script not found, skipping"
fi

# --- Step 5: Config and backups (ask first) ---
if [ -d "$CONFIG_DIR" ]; then
    info "Config directory found: $CONFIG_DIR"
    info "This includes your settings and any config backups."
    REPLY=$(ask "Remove it too? (y/n)")
    case "$REPLY" in
        y|Y)
            rm -rf "$CONFIG_DIR"
            success "Config directory removed"
            ;;
        *)
            info "Config directory kept: $CONFIG_DIR"
            ;;
    esac
fi

# --- Step 6: Log file (ask first) ---
if [ -f "/var/log/passwall_watchdog.log" ] || [ -f "/var/log/passwall_watchdog.log.old" ]; then
    REPLY=$(ask "Remove log files too? (y/n)")
    case "$REPLY" in
        y|Y)
            rm -f /var/log/passwall_watchdog.log /var/log/passwall_watchdog.log.old
            success "Log files removed"
            ;;
        *)
            info "Log files kept"
            ;;
    esac
fi

echo ""
echo "========================================"
success "Uninstall complete."
info "Note: Passwall2 itself was not touched."
info "If you toggled it off via the watchdog, you may want to"
info "re-enable it manually: uci set passwall2.@global[0].enabled='1' && uci commit passwall2 && /etc/init.d/passwall2 restart"
echo "========================================"
echo ""
