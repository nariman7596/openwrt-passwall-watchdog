#!/bin/sh

# --- Paths ---
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/passwall_watchdog"
CONFIG_FILE="$CONFIG_DIR/watchdog.conf"
HOTPLUG_DIR="/etc/hotplug.d/button"
HOTPLUG_FILE="$HOTPLUG_DIR/99-passwall-watchdog"
INIT_FILE="/etc/init.d/passwall_watchdog"
BACKUP_DIR="$CONFIG_DIR/backup"
SCRIPT_NAME="Passwall_watchdog.sh"
REPO_RAW="https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main"

# --- Helpers ---
info()    { echo "  $1"; }
success() { echo "  [OK] $1"; }
warn()    { echo "  [!!] $1"; }
ask()     { printf "  >>> %s: " "$1" >&2; read -r REPLY; echo "$REPLY"; }

# --- Step 0: Dependency check ---
check_deps() {
    for cmd in curl uci pgrep killall; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            warn "Missing dependency: $cmd"
        fi
    done
    success "All dependencies found (curl, uci, pgrep, killall)"
}

# --- Step 1: Backup ---
backup_config() {
    mkdir -p "$BACKUP_DIR"
    if [ -f /etc/config/passwall2 ]; then
        local name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$BACKUP_DIR/$name" /etc/config/passwall2 2>/dev/null
        success "Config backed up: $BACKUP_DIR/$name"
    else
        warn "passwall2 config not found, skipping backup"
    fi
}

# --- Step 2: LED detection ---
detect_leds() {
    LED_RED=$(find /sys/class/leds/ -maxdepth 1 -name "*red*" | head -n 1)
    LED_GREEN=$(find /sys/class/leds/ -maxdepth 1 -name "*green*" | head -n 1)
    LED_BLUE=$(find /sys/class/leds/ -maxdepth 1 -name "*blue*" | head -n 1)

    if [ -z "$LED_RED" ] || [ -z "$LED_GREEN" ] || [ -z "$LED_BLUE" ]; then
        warn "Could not auto-detect all LEDs."
        info "Available LEDs:"
        ls /sys/class/leds/ >&2
        LED_RED=$(ask "Enter full path for RED LED")
        LED_GREEN=$(ask "Enter full path for GREEN LED")
        LED_BLUE=$(ask "Enter full path for BLUE LED")
    else
        success "LEDs detected:"
        info "  RED:   $LED_RED"
        info "  GREEN: $LED_GREEN"
        info "  BLUE:  $LED_BLUE"
        info "If any of these look wrong (e.g. matched an unrelated LED),"
        info "you can edit $CONFIG_FILE manually after installation."
    fi
}

# --- Step 3: Button mapping ---
map_button() {
    info ""
    info "Default toggle button is WPS (BTN_9)."
    info "If you want a different button, find its name by running:"
    info "  logread -f"
    info "and pressing the button — it will show in the hotplug log."
    BUTTON_NAME=$(ask "Press Enter to use WPS, or type the button name (e.g. BTN_0)")
    [ -z "$BUTTON_NAME" ] && BUTTON_NAME="BTN_9"
    success "Toggle button set to: $BUTTON_NAME"
}

# --- Step 4: Write hotplug trigger ---
write_hotplug() {
    mkdir -p "$HOTPLUG_DIR"
    cat > "$HOTPLUG_FILE" << EOF
#!/bin/sh
if [ "\$BUTTON" = "$BUTTON_NAME" ] && [ "\$ACTION" = "released" ]; then
    $INSTALL_DIR/$SCRIPT_NAME toggle
fi
EOF
    chmod +x "$HOTPLUG_FILE"
    success "Hotplug trigger written: $HOTPLUG_FILE"
}

# --- Step 5: Write config ---
write_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# Network
PING_TARGET="8.8.8.8"
WAN_TOLERANCE=2
BOOT_DELAY=20

# Proxy
TEST_URL="https://www.youtube.com"
SOCKS_PORT=1070
PROXY_TOLERANCE=3

# Hardware - LED paths (auto-detected)
LED_RED="$LED_RED"
LED_GREEN="$LED_GREEN"
LED_BLUE="$LED_BLUE"

# Toggle button
TOGGLE_BUTTON="$BUTTON_NAME"

# System
LOG_FILE="/var/log/passwall_watchdog.log"
PID_FILE="/tmp/passwall_watchdog.pid"
EOF
    success "Config written: $CONFIG_FILE"
}

# --- Step 6: Install main script ---
install_script() {
    curl -fsSL "$REPO_RAW/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    success "Main script installed: $INSTALL_DIR/$SCRIPT_NAME"
}

# --- Step 7: Install init service ---
install_init() {
    curl -fsSL "$REPO_RAW/watchdog_init" -o "$INIT_FILE"
    chmod +x "$INIT_FILE"
    "$INIT_FILE" enable
    success "Init service installed and enabled"
}

# --- Main ---
echo ""
echo "========================================"
echo "   Passwall Watchdog Installer"
echo "========================================"
echo ""

check_deps
backup_config
detect_leds
map_button
write_hotplug
write_config
install_script
install_init

echo ""
echo "========================================"
success "Installation complete."
info "Toggle button: $BUTTON_NAME"
info "Logs: $LOG_FILE"
info "Starting watchdog now..."
"$INIT_FILE" start
echo "========================================"
echo ""
