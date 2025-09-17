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

## Monitors and Widgets (Ready to Use)

- Service widgets: check_status targeting windows_service.state, grouped by role and service_group
- Log widgets: log_stream queries aligned to channel and @evt.id (Datadog-normalized attributes)
- Role-based monitor JSONs (per directory):
  - distribution-point/distribution-point_monitor.json
  - management-point/management-point_monitor.json
  - site-server/site-server_monitor.json
  - sql-server/sql-server_monitor.json
  - sql-reporting-server/sql-reporting-server_monitor.json

Optional: import these monitors into Datadog via the Monitors API or UI (Create monitor from JSON).

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
├── site-server/
│   ├── datadog.yaml
│   ├── site-server_service_widget.json
│   ├── site-server_events_widget.json
│   └── site-server_monitor.json
├── management-point/
│   ├── datadog.yaml
│   ├── management-point_service_widget.json
│   ├── management-point_events_widget.json
│   └── management-point_monitor.json
├── distribution-point/
│   ├── datadog.yaml
│   ├── distribution-point_service_widget.json
│   ├── distribution-point_events_widget.json
│   └── distribution-point_monitor.json
├── sql-server/
│   ├── datadog.yaml
│   ├── sql-server_service_widget.json
│   ├── sql-server_events_widget.json
│   └── sql-server_monitor.json
├── sql-reporting-server/
│   ├── datadog.yaml
│   ├── sql-reporting-server_service_widget.json
│   ├── sql-reporting-server_events_widget.json
│   └── sql-reporting-server_monitor.json
├── dashboards/
├── common/
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
