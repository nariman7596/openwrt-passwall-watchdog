#!/bin/sh

# --- Load configuration ---
. /etc/passwall_watchdog/watchdog.conf

LOCK_FILE="/tmp/passwall_watchdog.lock"

# --- Lock/Unlock ---
acquire_lock() {
    local i=0
    while [ -f "$LOCK_FILE" ]; do
        i=$((i + 1))
        [ "$i" -ge 10 ] && return 1
        sleep 0.5
    done
    echo $$ > "$LOCK_FILE"
    return 0
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# --- LED control ---
set_led() {
    acquire_lock || return 1

    echo 0 > "$LED_RED/brightness"
    echo 0 > "$LED_GREEN/brightness"
    echo 0 > "$LED_BLUE/brightness"

    case "$1" in
        green) echo 1 > "$LED_GREEN/brightness" ;;
        red)   echo 1 > "$LED_RED/brightness"   ;;
        blue)  echo 1 > "$LED_BLUE/brightness"  ;;
        pink)
            echo 1 > "$LED_RED/brightness"
            echo 1 > "$LED_BLUE/brightness"
            ;;
    esac

    release_lock
}

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$LOG_FILE"
}

# --- Log rotation: keep max ~500KB, one backup ---
rotate_log() {
    [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -gt 512000 ] && \
        mv "$LOG_FILE" "${LOG_FILE}.old"
}

# --- Kill proxy cores ---
kill_cores() {
    killall -9 xray sing-box ss-local ssr-local 2>/dev/null
}

# --- Connectivity checks ---
check_wan() {
    local fail=0
    local i=1
    while [ "$i" -le "$WAN_TOLERANCE" ]; do
        ping -c 1 -W 1 "$PING_TARGET" > /dev/null 2>&1 || fail=$((fail + 1))
        i=$((i + 1))
    done
    [ "$fail" -lt "$WAN_TOLERANCE" ]
}

check_core() {
    pgrep -f "xray|sing-box" > /dev/null 2>&1
}

check_proxy() {
    local fail=0
    local i=1
    while [ "$i" -le "$PROXY_TOLERANCE" ]; do
        curl -I -s \
            --socks5-hostname "127.0.0.1:$SOCKS_PORT" \
            --max-time 5 \
            "$TEST_URL" > /dev/null 2>&1 || fail=$((fail + 1))
        i=$((i + 1))
    done
    [ "$fail" -lt "$PROXY_TOLERANCE" ]
}

# --- Toggle passwall on/off ---
toggle() {
    local state
    state=$(uci get passwall2.@global[0].enabled 2>/dev/null)

    if [ "$state" = "1" ]; then
        uci set passwall2.@global[0].enabled='0'
        uci commit passwall2
        /etc/init.d/passwall2 stop
        kill_cores
        set_led red
        log "WARN" "Passwall disabled via toggle"
    else
        uci set passwall2.@global[0].enabled='1'
        uci commit passwall2
        /etc/init.d/passwall2 restart
        set_led blue
        log "WARN" "Passwall enabled via toggle"
    fi
}

# --- Main watchdog loop ---
run_watchdog() {
    echo $$ > "$PID_FILE"
    log "WARN" "Watchdog started (PID $$)"

    local proxy_fail_streak=0

    while [ -f "$PID_FILE" ]; do
        rotate_log

        if ! check_wan; then
            set_led pink
            log "WARN" "WAN down"
            proxy_fail_streak=0
            sleep 30
            continue
        fi

        state=$(uci get passwall2.@global[0].enabled 2>/dev/null)
        if [ "$state" != "1" ]; then
            set_led red
            kill_cores
            proxy_fail_streak=0
            sleep 5
            continue
        fi

        if ! check_core; then
            set_led red
            log "WARN" "Core process down, restarting passwall"
            /etc/init.d/passwall2 restart > /dev/null 2>&1
            proxy_fail_streak=0
            sleep 10
            continue
        fi

        if check_proxy; then
            set_led green
            proxy_fail_streak=0
        else
            proxy_fail_streak=$((proxy_fail_streak + 1))
            set_led blue
            log "WARN" "Core up but proxy tunnel failing (streak: $proxy_fail_streak)"
            if [ "$proxy_fail_streak" -ge 3 ]; then
                log "WARN" "Proxy failing consistently, restarting passwall"
                /etc/init.d/passwall2 restart > /dev/null 2>&1
                proxy_fail_streak=0
                sleep 10
            fi
        fi

        sleep 5
    done
}

# --- Entry point ---
case "$1" in
    toggle)
        toggle
        ;;
    boot)
        sleep "$BOOT_DELAY"
        state=$(uci get passwall2.@global[0].enabled 2>/dev/null)
        [ "$state" = "1" ] && /etc/init.d/passwall2 restart
        # Kill any existing watchdog instance before starting fresh
        old_pid=$(cat "$PID_FILE" 2>/dev/null)
        [ -n "$old_pid" ] && kill -9 "$old_pid" 2>/dev/null
        run_watchdog &
        ;;
    *)
        old_pid=$(cat "$PID_FILE" 2>/dev/null)
        [ -n "$old_pid" ] && kill -9 "$old_pid" 2>/dev/null
        run_watchdog &
        ;;
esac
