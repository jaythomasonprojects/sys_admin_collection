# Zabbix Agent Configuration Deployment

## Purpose

Provide a USB-ready PowerShell script that replaces the configuration of an installed Zabbix Agent 1 or Agent 2 installation and restarts its service.

## USB Contents

- `Deploy-ZabbixConfig.ps1`
- `zabbix_agentd.conf` for Agent 1
- `zabbix_agent2.conf` for Agent 2

## Behaviour

The script requires an elevated PowerShell session. It detects the installed service, preferring neither version: it exits if both `Zabbix Agent` and `Zabbix Agent 2` exist, or if neither exists.

For the detected service, it copies the matching configuration from the script directory to the default installation path, then restarts that service. It writes a concise success message or exits with an error.

## Constraints

- No self-elevation, prompts, backups, logs, installer-path discovery, or external dependencies.
- Only default installation paths are supported.
- Replacing the configuration is deliberate and irreversible within the script.

## Validation

Run the script elevated on `192.168.42.234`, confirm it identifies Zabbix Agent 2, replaces the configuration, restarts the service, and leaves the service running.
