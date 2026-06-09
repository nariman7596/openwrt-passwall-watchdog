# Passwall Watchdog

A robust monitoring service designed to ensure the stability of Passwall cores on OpenWrt routers. This tool utilizes a **Check-before-Restart** logic, preventing unnecessary service disruptions caused by "blind" watchdog scripts.

### Overview
This project is currently optimized for the **RAX3000M** router, providing deep hardware-level integration. It features a modular architecture that can be easily adapted to other router models.

### Key Features
* **RAX3000M Optimized:** Specifically tuned for the hardware characteristics and LED paths of the RAX3000M.
* **Fully Customizable:** Easily configure hardware paths (LEDs/WPS Button), network test targets (Ping/HTTP), and the **Status Protocol** (define what each LED color represents) via a simple, well-documented `watchdog.conf` file.
* **Intelligent Monitoring:** Connectivity testing using ping and real-world HTTP health checks.
* **Safety First:** Includes an automated backup system to preserve your current router configuration before applying any changes.
* **Modular Design:** Built with future-proofing in mind; the configuration logic allows for easy adaptation to other router models.

### How it Works
The watchdog monitors your internet connection and proxy core status in real-time. It uses a custom status protocol to communicate system health through your router's existing LED indicators:
- **Status Protocol:** You can define exactly what each LED combination represents, ensuring the visual feedback matches your specific setup.
