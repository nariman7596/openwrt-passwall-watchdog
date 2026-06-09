# Passwall Watchdog - Monitoring Service Stability

A lightweight, robust monitoring tool to keep your Passwall core running reliably. This project is currently optimized specifically for the RAX3000M router, ensuring hardware-level integration, with a modular architecture designed for future expansion to other models.

### Why this project?
Most existing watchdog scripts rely on "blind" restarts, which often cause further system instability. I designed this script with a **Check-before-Restart** logic, ensuring that action is only taken when the service has truly failed.

### Key Features
* **RAX3000M Optimized:** Specifically tuned for the hardware characteristics and LED paths of the RAX3000M.
* **Fully Customizable:** Easily configure hardware paths (LEDs/Buttons), network test targets (Ping/HTTP), and the **Status Protocol** (define what each LED color represents) via a simple, well-documented `watchdog.conf` file.
* **Intelligent Monitoring:** Connectivity testing using ping and real-world HTTP health checks.
* **Safety First:** Includes an automated backup system to preserve your current router configuration before applying any changes.
* **Modular Design:** Built with future-proofing in mind; the configuration logic allows for easy adaptation to other router models.
