#!/bin/sh

# ==============================================================================
# Passwall Watchdog - Intelligent Interactive Installer
# ==============================================================================

CONFIG_DIR="/etc/passwall_watchdog"
CONFIG_FILE="$CONFIG_DIR/watchdog.conf"
PID_FILE="/tmp/passwall_watchdog.pid"
HOTPLUG_DIR="/etc/hotplug.d/button"
HOTPLUG_FILE="$HOTPLUG_DIR/99-passwall-watchdog"
BACKUP_DIR="$CONFIG_DIR/backup"

echo "--- Passwall Watchdog: Initializing Smart Installation ---"

# 1. Automatic Hardware Detection
LED_RED=$(find /sys/class/leds/ -name "*red*" | head -n 1)
LED_GREEN=$(find /sys/class/leds/ -name "*green*" | head -n 1)
LED_BLUE=$(find /sys/class/leds/ -name "*blue*" | head -n 1)

# 2. Backup Phase
mkdir -p "$BACKUP_DIR"
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" /etc/config/passwall2 > /dev/null 2>&1
echo -e "Backup created at: \033[1m$BACKUP_DIR/$BACKUP_NAME\033[0m"

# 3. Smart Button Mapping
echo "Press the desired button for toggling Passwall now..."
BUTTON_NAME=$(logread -f | grep -m 1 "button" | awk -F'button ' '{print $2}' | awk '{print $1}')
echo "Button '$BUTTON_NAME' mapped."

cat << EOF > "$HOTPLUG_FILE"
#!/bin/sh
if [ "\$BUTTON" = "$BUTTON_NAME" ] && [ "\$ACTION" = "pressed" ]; then
    /etc/passwall_watchdog.sh toggle
fi
EOF
chmod +x "$HOTPLUG_FILE"

# 4. Status Protocol Configuration
echo "--- Configuring Status Protocol ---"
STATES=("Internet OK + Passwall Active + Free Net" "Internet OK + Passwall Active + No Free Net" "Internet OK + Passwall Inactive" "No Internet Connection")
AVAILABLE="Green, Blue, Red, Pink"

declare -A PROTOCOL_MAP
for state in "${STATES[@]}"; do
    echo "State: $state"
    echo "Remaining Colors: $AVAILABLE"
    read -p "Select color: " choice
    PROTOCOL_MAP["$state"]=$choice
    AVAILABLE=${AVAILABLE//$choice/}
done

# 5. Save Configuration
mkdir -p "$CONFIG_DIR"
cat << EOF > "$CONFIG_FILE"
PING_TARGET="8.8.8.8"
TEST_URL="https://www.youtube.com"
BUTTON_WPS="$BUTTON_NAME"
LED_RED="$LED_RED"
LED_GREEN="$LED_GREEN"
LED_BLUE="$LED_BLUE"
PID_FILE="$PID_FILE"
# Protocol Mapping:
EOF

for state in "${!PROTOCOL_MAP[@]}"; do
    echo "$state=\"${PROTOCOL_MAP[$state]}\"" >> "$CONFIG_FILE"
done

echo "Installation complete. Config saved to $CONFIG_FILE."
