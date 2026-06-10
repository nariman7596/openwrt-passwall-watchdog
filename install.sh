#!/bin/sh

# Download the main script
echo "Downloading Passwall Watchdog..."
wget -qO /usr/bin/passwall_watchdog.sh https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main/passwall_watchdog.sh

# Set executable permission
chmod +x /usr/bin/passwall_watchdog.sh

# Create basic init script to start on boot
echo "Creating boot service..."
cat << 'EOF' > /etc/init.d/passwall_watchdog
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_command /usr/bin/passwall_watchdog.sh
    procd_set_param respawn
    procd_close_instance
}
EOF

chmod +x /etc/init.d/passwall_watchdog
/etc/init.d/passwall_watchdog enable
/etc/init.d/passwall_watchdog start

echo "Installation complete! Watchdog is now running."
