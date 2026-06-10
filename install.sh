#!/bin/sh

# --- Paths ---
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/passwall_watchdog"
CONFIG_FILE="$CONFIG_DIR/watchdog.conf"
HOTPLUG_DIR="/etc/hotplug.d/button"
HOTPLUG_FILE="$HOTPLUG_DIR/99-passwall-watchdog"
INIT_FILE="/etc/init.d/passwall_watchdog"
BACKUP_DIR="$CONFIG_DIR/backup"
SCRIPT_NAME="passwall_watchdog.sh"

# --- Helpers ---
info()    { echo "  $1"; }
success() { echo "  [OK] $1"; }
warn()    { echo "  [!!] $1"; }
ask()     { printf "  >>> %s: " "$1"; read -r REPLY; echo "$REPLY"; }

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
        ls /sys/class/leds/
        LED_RED=$(ask "Enter full path for RED LED")
        LED_GREEN=$(ask "Enter full path for GREEN LED")
        LED_BLUE=$(ask "Enter full path for BLUE LED")
    else
        success "LEDs detected:"
        info "  RED:   $LED_RED"
        info "  GREEN: $LED_GREEN"
        info "  BLUE:  $LED_BLUE"
    fi
}

# --- Step 3: Button mapping ---
map_button() {
    info "Available buttons on this device:"
    ls /sys/class/input/ 2>/dev/null

    info ""
    info "Default toggle button is WPS."
    info "Press Enter to use WPS, or type another button name:"
    BUTTON_NAME=$(ask "Button name [WPS]")
    [ -z "$BUTTON_NAME" ] && BUTTON_NAME="WPS"
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

# --- Step 5: Write config
