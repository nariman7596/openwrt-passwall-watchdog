
# Passwall Watchdog for OpenWrt

A robust, modular monitoring service engineered to ensure high-availability and stability for Passwall cores on OpenWrt routers. This tool implements a sophisticated "Check-before-Restart" logic, effectively preventing the service disruptions and flapping issues common in traditional, blind watchdog implementations.

## Quick Install
Deploy the service instantly via your router's SSH terminal:

```bash
sh -c "$(curl -fsSL [https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main/install.sh](https://raw.githubusercontent.com/nariman7596/openwrt-passwall-watchdog/main/install.sh))"

```
## Engineering Logic
The watchdog operates on a three-tier validation sequence, ensuring that the system only attempts recovery when a failure is confirmed:
 1. **WAN Check:** Verifies raw upstream internet connectivity.
 2. **Core Validation:** Performs process-level integrity checks for the Passwall service.
 3. **Proxy Integrity:** Utilizes high-precision HTTP-based traffic routing verification (YouTube-bound) to ensure the tunnel is not just active, but functional.
## Visual Status Protocol
The router's status LED provides immediate, real-time telemetry regarding the system's operational health:
| State | Indicator | Condition |
|---|---|---|
| **Critical** | PINK | WAN connection lost; primary upstream down. |
| **Service Down** | RED | Passwall core process unresponsive. |
| **Tunnel Failed** | BLUE | Core active, but proxy traffic routing failing. |
| **Stable** | GREEN | System nominal, tunnel verified and operational. |
## Technical Customization
Designed with a "Safety-First" philosophy, the system preserves existing configurations by default. Environment-specific variables are exposed in the header of /usr/bin/passwall_watchdog.sh, allowing users to fine-tune the following parameters to match specific hardware footprints or unique routing requirements:
 * **LED_TRIGGER**: Adjust the hardware-specific path for status LED control.
 * **TEST_URL**: Update the target endpoint for proxy health verification.
 * **WAN_TOLERANCE / CORE_TOLERANCE**: Configure validation thresholds to mitigate false positives in high-latency or load-balanced environments.
*Developed for OpenWrt enthusiasts requiring enterprise-grade stability on consumer-grade hardware.*
```

```
