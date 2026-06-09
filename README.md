# Passwall Watchdog - Monitoring Service Stability 

A lightweight, robust monitoring tool to keep your Passwall core running reliably. This project is currently optimized specifically for the RAX3000M router, ensuring hardware-level Integration, with a modular architecture designed for future Expansion to other models.


# Why this project?

Most existing watchdog scripts rely on "blind" restarts, which often cause further system instability. I designed this script with a Check-before-Restart logic, ensuring that action is only taken when the service has truly failed.


# Key Features

Specifically tuned for the hardware characteristics and LED paths of the RAX3000M. Built with future-proofing in mind; the configuration logic allows for easy adaptation to other router models as the project grows.
Intelligent connectivity testing using ping and real-world HTTP health checks.
Includes an automated backup system to preserve your current router configuration before applying any changes.
Easily configure LED paths, test targets, and physical button behavior via a simple configuration file.
