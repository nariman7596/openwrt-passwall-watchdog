#!/bin/sh

# --- Configuration Section ---
# WAN and Core tolerance to prevent false positives and flapping
WAN_TOLERANCE=2
CORE_TOLERANCE=4
LOG_FILE="/var/log/passwall_watchdog.log"
# Hardware specific LED trigger path
LED_TRIGGER="/sys/class/leds/status_led/trigger"

# --- Helper Functions ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_wan() {
    # Verify raw internet connectivity via reliable upstream
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    return $?
}

check_core() {
    # Check if passwall process is active in the process list
    pgrep -f "passwall" > /dev/null 2>&1
    return $?
}

check_proxy_connectivity() {
    # Using YouTube to ensure traffic is forced through the tunnel
    # --max-time 5 ensures we don't hang if the tunnel is slow
    curl -I -s --max-time 5 https://www.youtube.com > /dev/null 2>&1
    return $?
}

# --- Main Logic Loop ---
log "Watchdog service initialization complete."

while true; do
    # 1. Validate WAN connectivity with defined tolerance
    wan_fail_count=0
    for i in $(seq 1 $WAN_TOLERANCE); do
        check_wan || wan_fail_count=$((wan_fail_count + 1))
    done

    if [ $wan_fail_count -eq $WAN_TOLERANCE ]; then
        echo "PINK" > $LED_TRIGGER
        log "WAN connectivity lost. Status: PINK"
        sleep 30
    else
        # 2. WAN is up, evaluate Core and Proxy status
        if ! check_core; then
            echo "RED" > $LED_TRIGGER
            log "Passwall Core service is down. Status: RED"
        else
            # 3. Core is up, assess Proxy health with higher tolerance for Load Balancing
            proxy_fail_count=0
            for i in $(seq 1 $CORE_TOLERANCE); do
                check_proxy_connectivity || proxy_fail_count=$((proxy_fail_count + 1))
            done

            if [ $proxy_fail_count -eq $CORE_TOLERANCE ]; then
                echo "BLUE" > $LED_TRIGGER
                log "Core active but proxy connection failed. Status: BLUE"
            else
                echo "GREEN" > $LED_TRIGGER
                log "System stable and traffic flow verified. Status: GREEN"
            fi
        fi
        sleep 5
    fi
done
