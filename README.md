# Passwall Watchdog for OpenWrt

A lightweight monitoring daemon for Passwall cores on OpenWrt routers.  
Unlike traditional watchdog scripts, this tool **validates before it acts** — no blind restarts, no unnecessary flapping.

----
## How It Works

The watchdog runs a three-tier check sequence before taking any action:

1. **WAN Check** — Verifies raw upstream internet connectivity.
1. **Core Validation** — Confirms the Passwall process is alive and responsive.
1. **Proxy Integrity** — Sends a real HTTP request through the tunnel to verify it’s actually routing traffic (not just “up”).

A restart is only triggered when a failure is confirmed at the appropriate tier.  
This eliminates false positives caused by transient latency or brief upstream hiccups.

-----

## LED Status

Real-time system state is reported via the router’s status LED:

|Color  |Meaning                                       |
|-------|----------------------------------------------|
|🟢 GREEN|All clear — WAN up, tunnel verified           |
|🟣 PINK |WAN down — upstream connectivity lost         |
|🔴 RED  |Core down — Passwall process unresponsive     |
|🔵 BLUE |Core up, tunnel broken — proxy traffic failing|

-----

## Configuration

All tunable parameters are defined at the top of `/usr/bin/passwall_watchdog.sh`:

|Variable        |Description                                       |
|----------------|--------------------------------------------------|
|`LED_TRIGGER`   |Hardware path for the status LED (device-specific)|
|`TEST_URL`      |Target URL used for proxy health checks           |
|`WAN_TOLERANCE` |Retry threshold before declaring WAN failure      |
|`CORE_TOLERANCE`|Retry threshold before restarting the core        |


> The installer automatically backs up your current router configuration before making any changes.

-----

## Compatibility

Primarily developed and tested on the **RAX3000M**.  
The modular design makes it adaptable to other OpenWrt-supported hardware with minimal changes to `LED_TRIGGER`.

-----

## License

MIT
