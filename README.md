# SCCM Datadog Monitoring Configuration Package

Comprehensive Datadog monitoring configurations for Microsoft System Center Configuration Manager (SCCM) servers using Windows Authentication for enhanced security and LCD monitoring approach.

## Prerequisites

- Active Datadog account with API key
- Windows Server 2016+ with PowerShell 5.1+
- Administrator privileges on SCCM servers
- Datadog Agent service account with SQL Server access (Windows Authentication)

## Components

- Site Server: Basic SCCM site server monitoring with essential services
- Management Point: Client communication endpoint monitoring
- Distribution Point: Content distribution monitoring with IIS
- SQL Server: Database performance monitoring with Windows Authentication
- SQL Reporting Server: SSRS monitoring with Windows Authentication

## Monitors and Dashboards (Ready to Use)

- Dashboards (templates in dashboards/):
  - dash-sccm-sql-unified-dashboard.json
  - dash-sccm-sql-applications.json
  - dash-windows-server-health.json
- Monitors (JSON in dashboards/, prefixed monitor-*.json):
  - dashboards/monitor-site-server.json
  - dashboards/monitor-management-point.json
  - dashboards/monitor-distribution-point.json
  - dashboards/monitor-sql-server.json
  - dashboards/monitor-sql-reporting-server.json
- Conventions:
  - Service widgets/monitors use windows_service.state grouped by role and service_group
  - service_group values are namespaced as sccm-* (e.g., sccm-web-infrastructure, sccm-sql-server-core)
  - Log widgets/monitors use normalized channel and @evt.id attributes
  - Dashboards filter by $applicationid and $domain template variables (no hard-coded environment tags)

Optional: import these monitors via the Datadog UI (Create monitor from JSON) or Monitors API.

## Quick Start

1. Clone this repository to your deployment server
2. Update `servers.json` with your SCCM server details
3. Replace `YOUR_API_KEY_HERE` with your actual Datadog API key in each role’s `datadog.yaml`
4. Run the deployment script:
   ```powershell
   .\Deploy-DatadogConfigs.ps1
   ```
5. Optional: import the monitor JSON for each role into Datadog

## Security

All SQL Server connections use Windows Authentication (`Trusted_Connection=yes`) eliminating the need for stored credentials. Ensure the Datadog Agent service account has appropriate SQL Server permissions.

## Repository Structure

```
datadog-fun/
├── site-server/
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── iis.d/
├── management-point/
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── iis.d/
├── distribution-point/
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── iis.d/
├── sql-server/
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── sqlserver.d/
├── sql-reporting-server/
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       └── sqlserver.d/
├── dashboards/
│   ├── dash-sccm-sql-unified-dashboard.json
│   ├── dash-sccm-sql-applications.json
│   ├── dash-windows-server-health.json
│   ├── monitor-site-server.json
│   ├── monitor-management-point.json
│   ├── monitor-distribution-point.json
│   ├── monitor-sql-server.json
│   └── monitor-sql-reporting-server.json
├── common/
│   ├── recommended-thresholds.yaml
│   └── system-probe.yaml
├── servers.json
└── Deploy-DatadogConfigs.ps1
```

## Notes on Agent Config

- windows_service.d emits service checks (no metrics). Widgets/monitors use `windows_service.state`
- win32_event_log.d uses `channel_path` and EventID patterns; Datadog normalizes to `channel` and `evt.id` used in queries/monitors
- process.d is neutralized (instances: []) to avoid double collection; Process Agent handles process data

## Deployment Script Highlights

- Copies only `datadog.yaml` and `conf.d/*` to `C:\ProgramData\Datadog` (avoids non-Agent files)
- Creates backups on the target before overwrite
- Restarts Agent via `agent.exe restart-service`
- Optionally invokes `agent.exe status` post-restart for quick validation
- Supports `-TestMode $true` for dry-run validation

## Documentation

- [Project_Details.md](Project_Details.md) - Comprehensive project information and setup guide
- [Project_Components.md](Project_Components.md) - Detailed component descriptions and structure

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
