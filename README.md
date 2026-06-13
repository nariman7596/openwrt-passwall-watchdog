# Passwall Watchdog for OpenWrt

A lightweight monitoring daemon for Passwall2 on OpenWrt routers.
Validates before acting — no blind restarts, no unnecessary flapping.

---

## Quick Install

Run this in your router's SSH terminal:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main/install.sh)"
```

During installation you'll be asked to confirm the toggle button (default: WPS).
The installer checks for required dependencies (`curl`, `uci`, `pgrep`, `killall`),
auto-detects your LED paths, writes everything to `/etc/passwall_watchdog/watchdog.conf`,
The watchdog service starts automatically once installation finishes.

If `curl` is missing (common on minimal images), install it first:

```sh
opkg update && opkg install curl
```

---

## How It Works

The watchdog runs a three-tier check before taking any action:

1. **WAN** — Pings an upstream target to verify raw internet connectivity.
2. **Core** — Checks whether the `xray` or `sing-box` process is actually running.
3. **Proxy** — Sends a real HTTP request through the SOCKS5 tunnel to confirm traffic is flowing, not just that the process is up.

A restart only happens when a failure is confirmed at the right tier.
Transient hiccups and brief upstream drops won't trigger unnecessary restarts.

---

## LED Status

| Color   | Meaning                                  |
|---------|-------------------------------------------|
| 🟢 Green | WAN up, core running, tunnel verified      |
| 🔵 Blue  | Core up, but proxy tunnel is failing       |
| 🔴 Red   | Core down, or Passwall manually disabled   |
| 🩷 Pink  | WAN down — no upstream connectivity        |

---

## Hardware Toggle

Press the WPS button to toggle Passwall on or off without touching LuCI or SSH.
The button is mapped during installation via OpenWrt's hotplug system.

To use a different button, edit `/etc/hotplug.d/button/99-passwall-watchdog`
and re-run the installer, or update the file manually.

---

## Service Management

The watchdog runs as a standard OpenWrt init service (`passwall_watchdog`)
and will automatically restart if it ever stops unexpectedly.

```sh
/etc/init.d/passwall_watchdog start    # start the watchdog
/etc/init.d/passwall_watchdog stop     # stop the watchdog
/etc/init.d/passwall_watchdog restart  # restart the watchdog
/etc/init.d/passwall_watchdog enable   # start on boot (done by installer)
/etc/init.d/passwall_watchdog disable  # don't start on boot
```

After editing `watchdog.conf`, restart the service for changes to take effect:

```sh
/etc/init.d/passwall_watchdog restart
```

---

## Configuration

All parameters live in `/etc/passwall_watchdog/watchdog.conf`:

| Variable             | Description                                              |
|----------------------|-----------------------------------------------------------|
| `PING_TARGET`        | Host used for WAN check                                  |
| `WAN_TOLERANCE`      | Failed pings before declaring WAN down                   |
| `TEST_URL`           | URL used for proxy tunnel verification                   |
| `SOCKS_PORT`         | Local SOCKS5 port exposed by Passwall                    |
| `PROXY_TOLERANCE`    | Failed proxy checks before marking tunnel broken         |
| `BOOT_DELAY`         | Seconds to wait after boot before starting (default: 20) |
| `LED_RED/GREEN/BLUE` | Hardware paths for status LEDs                           |
| `LOG_FILE`           | Path to the watchdog log                                 |
| `PID_FILE`           | Path to the watchdog's PID file                          |

---

## Logs

```sh
tail -f /var/log/passwall_watchdog.log
```

The log file auto-rotates once it exceeds ~500KB, keeping one backup (`.old`).

---

## Uninstall

Run the uninstaller from the router's SSH terminal:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main/uninstall.sh)"
```

This stops and removes the service, hotplug trigger, and main script.
You'll be asked separately whether to also remove the config directory
(settings + backups) and log files. Passwall2 itself is left untouched.

---

## Compatibility

Developed and tested on the RAX3000M.
Should work on any OpenWrt device — the only hardware-specific part is the LED paths,
which the installer detects automatically (with a manual fallback prompt if detection fails).

---

## License

MIT
