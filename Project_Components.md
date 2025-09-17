# SCCM Datadog Monitoring - Project Components

This document provides a structural overview of the project components and their specific monitoring configurations. Each component is designed for specific SCCM server roles with tailored monitoring focused on role-specific services and performance metrics.

## Project Structure

```
datadog-fun/
├── site-server/                    # Primary Site Server configuration
│   ├── datadog.yaml                # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/      # SCCM service monitoring (service checks)
│       ├── win32_event_log.d/      # Windows event log monitoring
│       ├── wmi_check.d/            # WMI performance counters
│       └── iis.d/                  # IIS web server monitoring
├── management-point/               # Management Point configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── iis.d/
├── distribution-point/             # Distribution Point configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── iis.d/
├── sql-server/                     # SQL Database Server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── sqlserver.d/            # SQL Server monitoring
├── sql-reporting-server/           # SQL Reporting Server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── sqlserver.d/
├── dashboards/                     # Datadog dashboards & monitors (JSON)
│   ├── dash-sccm-sql-unified-dashboard.json
│   ├── dash-sccm-sql-applications.json
│   ├── dash-windows-server-health.json
│   ├── monitor-site-server.json
│   ├── monitor-management-point.json
│   ├── monitor-distribution-point.json
│   ├── monitor-sql-server.json
│   └── monitor-sql-reporting-server.json
├── common/                         # Shared configuration files
│   ├── recommended-thresholds.yaml
│   └── system-probe.yaml
├── servers.json                    # Server inventory configuration
└── Deploy-DatadogConfigs.ps1       # Automated deployment script
```

## Component Descriptions

### datadog.yaml
Main Datadog Agent configuration file containing API key, logging, and agent parameters. Each role carries role and app tags; SQL roles use Windows Authentication.

- Removed hard-coded `environment:production` tag to keep configs portable. Use dashboard template variables ($applicationid, $domain) for scoping in visualization.

### windows_service.d
Monitors critical Windows services specific to each SCCM role. Emits a service check (`windows_service.state`) and no metrics. Used by:
- Service widgets (`check_status`) grouped by `role` and `service_group`
- Service check monitors per role/group

Conventions:
- `service_group` values are namespaced as `sccm-*` (e.g., `sccm-web-infrastructure`, `sccm-sql-server-core`, `sccm-ssrs-core`, `sccm-windows-infrastructure`, `sccm-content-distribution`, `sccm-security-ssl`).

### win32_event_log.d
Windows Event Log collection using `channel_path` and include_at_match patterns on `"EventID"`. Datadog pipelines normalize these to `channel` and `evt.id`, which are used by:
- Log widgets (`log_stream`) in dashboards
- Log monitors (System/Application/Security categories)

### wmi_check.d
Windows performance counters. Covers CPU, memory, disk, network, and IIS (and SQL-specific counters on SQL Server). Provides consistent host telemetry across roles.

### iis.d
IIS monitoring for web-enabled roles with `include_per_site: true` and `include_wmi_metrics: true`. Provides per-site and aggregate metrics.

### sqlserver.d
SQL Server monitoring for DB-enabled roles using Windows Authentication (`Trusted_Connection=yes`) via ODBC. DBM is disabled by default; safe custom queries and SQL/SSRS logs are included where applicable.

## Dashboards and Monitors

- Dashboards (dashboards/*.json):
  - `dash-sccm-sql-unified-dashboard.json` — System KPIs plus role service health and role events.
  - `dash-sccm-sql-applications.json` — Role service health and role events only.
  - `dash-windows-server-health.json` — System CPU/MEM/DSK/NET overview.
- Monitors (dashboards/monitor-*.json):
  - Service check monitors target `windows_service.state`, grouped by `role` and `service_group` (sccm-*).
  - Log monitors use normalized `channel` and `@evt.id` filters.

Filtering guidance:
- Dashboards use `$applicationid` and `$domain` template variables (no hard-coded environment tags in agent configs).
