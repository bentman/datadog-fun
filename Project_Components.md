# SCCM Datadog Monitoring - Project Components

This document provides a structural overview of the project components and their specific monitoring configurations. Each component is designed for specific SCCM server roles with tailored monitoring focused on role-specific services and performance metrics.

## Project Structure

```
datadog-fun/
├── site-server/                    # Primary Site Server configuration
│   ├── datadog.yaml                # Main agent configuration
│   ├── site-server_service_widget.json
│   ├── site-server_events_widget.json
│   ├── site-server_monitor.json
│   └── conf.d/
│       ├── windows_service.d/      # SCCM service monitoring (service checks)
│       ├── win32_event_log.d/      # Windows event log monitoring
│       ├── wmi_check.d/            # WMI performance counters
│       ├── process.d/              # Neutralized (use Process Agent)
│       └── iis.d/                  # IIS web server monitoring
├── management-point/               # Management Point configuration
│   ├── datadog.yaml
│   ├── management-point_service_widget.json
│   ├── management-point_events_widget.json
│   ├── management-point_monitor.json
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/              # Neutralized
│       └── iis.d/
├── distribution-point/             # Distribution Point configuration
│   ├── datadog.yaml
│   ├── distribution-point_service_widget.json
│   ├── distribution-point_events_widget.json
│   ├── distribution-point_monitor.json
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/              # Neutralized
│       └── iis.d/
├── sql-server/                     # SQL Database Server configuration
│   ├── datadog.yaml
│   ├── sql-server_service_widget.json
│   ├── sql-server_events_widget.json
│   ├── sql-server_monitor.json
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/              # Neutralized
│       └── sqlserver.d/            # SQL Server monitoring
├── sql-reporting-server/           # SQL Reporting Server configuration
│   ├── datadog.yaml
│   ├── sql-reporting-server_service_widget.json
│   ├── sql-reporting-server_events_widget.json
│   ├── sql-reporting-server_monitor.json
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/              # Neutralized
│       └── sqlserver.d/
├── dashboards/                     # Datadog dashboard templates
│   ├── sccm-sql-applications.json
│   └── windows-server-health.json
├── common/                         # Shared configuration files
│   ├── recommended-thresholds.yaml
│   └── system-probe.yaml
├── servers.json                    # Server inventory configuration
└── Deploy-DatadogConfigs.ps1       # Automated deployment script
```

## Component Descriptions

### datadog.yaml
Main Datadog Agent configuration file containing API key, logging, and agent parameters. Each role carries role and app tags; SQL roles use Windows Authentication.

### windows_service.d
Monitors critical Windows services specific to each SCCM role. Emits a service check (`windows_service.state`) and no metrics. Used by:
- Service widgets (`check_status`) grouped by `role` and `service_group`
- Service check monitors per role/group

### win32_event_log.d
Windows Event Log collection using `channel_path` and include_at_match patterns on `"EventID"`. Datadog pipelines normalize these to `channel` and `evt.id`, which are used by:
- Per-role log_stream widgets
- Log monitors (System/Application/Security categories)

### wmi_check.d
Windows performance counters. Covers CPU, memory, disk, network, and IIS (and SQL-specific counters on SQL Server). Provides consistent host telemetry across roles.

### process.d
Legacy process check is neutralized (`instances: []`) to avoid double collection. Process visibility is provided by the Process Agent via `process_config.enabled` in `datadog.yaml`.

### iis.d
IIS monitoring for web-enabled roles with `include_per_site: true` and `include_wmi_metrics: true`. Provides per-site and aggregate metrics.

### sqlserver.d
SQL Server monitoring for DB-enabled roles using Windows Authentication (`Trusted_Connection=yes`) via ODBC. DBM is disabled by default; safe custom queries and SQL/SSRS logs are included where applicable.

## Dashboards and Monitors

- Widgets (per-role):
  - Service: `*_service_widget.json`
  - Events: `*_events_widget.json`
- Monitors (per-role): `*_monitor.json`
  - Service check monitors targeting `windows_service.state`
  - Log monitors using normalized `channel` and `@evt.id` filters

Note: Event Log widgets are per-role log_stream widgets; service widgets standardized to `check_status` on service checks. Environment-specific template variables are removed for portability.
