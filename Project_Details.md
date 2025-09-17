# SCCM Datadog Monitoring - Project Details

This document provides comprehensive information about the SCCM Datadog monitoring configuration package, including setup instructions, deployment methods, and troubleshooting guidance.

## Project Overview

This monitoring solution provides comprehensive observability for Microsoft System Center Configuration Manager (SCCM) environments using Datadog. The package includes role-specific configurations for all SCCM server types with Windows Authentication for enhanced security.

### Key Features

- Windows Authentication: All SQL Server connections use `Trusted_Connection=yes` eliminating credential storage
- Role-Specific Monitoring: Tailored configurations for each SCCM server role
- Automated Deployment: PowerShell script for consistent deployment across environments
- Comprehensive Coverage: System performance, SCCM services, SQL Server health, and Windows Event Logs
- Industry-Standard Thresholds: Pre-configured alerting thresholds based on best practices

### Quick Instructions (Very Brief)

- Update `servers.json`, set API key in each role’s `datadog.yaml`, run:
  ```powershell
  .\Deploy-DatadogConfigs.ps1
  ```
- Optional: import `*_monitor.json` per role into Datadog as monitors.
- Dashboards/widgets and conf.d are aligned to work out-of-the-box.

## Prerequisites

### Datadog Account Requirements
- Active Datadog account with appropriate licensing
- Datadog API key with write permissions
- Access to Datadog dashboard and alerting features

### Windows Server Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrator privileges on all SCCM servers
- Network connectivity to Datadog endpoints (outbound HTTPS)

### SCCM Environment Requirements
- SCCM Current Branch (version 1902 or later recommended)
- SQL Server 2016 or later
- Windows Authentication enabled on SQL Server
- Datadog Agent service account with SQL Server access

## Deployment Methods

### Automated Deployment (Recommended)

The `Deploy-DatadogConfigs.ps1` script provides automated deployment across all servers:

```powershell
# Standard deployment
.\Deploy-DatadogConfigs.ps1

# Test mode (no changes made)
.\Deploy-DatadogConfigs.ps1 -TestMode $true

# Custom options
.\Deploy-DatadogConfigs.ps1 -BackupConfigs $false -RestartService $false
```

**Script Features:**
- Automatic server role detection
- Configuration backup creation
- Service restart management (uses `agent.exe restart-service`)
- Comprehensive logging
- Test mode for validation
- Copies only Agent-relevant files (`datadog.yaml` and `conf.d/*`) to `C:\ProgramData\Datadog`
- Optional post-restart validation by invoking `agent.exe status`

### Manual Deployment

For environments requiring manual deployment:

1. Copy appropriate role configuration to target server
2. Place files in `C:\ProgramData\Datadog\`
3. Update API key in `datadog.yaml`
4. Restart Datadog Agent service

## Installation Steps

### 1. Environment Preparation

**Update Server Inventory:**
Edit `servers.json` with your SCCM server details in role-based groups:
```json
{
    "site-server": [
        "sccm-site01.contoso.com",
        "sccm-site02.contoso.com"
    ],
    "management-point": [
        "sccm-mp01.contoso.com",
        "sccm-mp02.contoso.com"
    ],
    "distribution-point": [
        "sccm-dp01.contoso.com",
        "sccm-dp02.contoso.com"
    ],
    "sql-server": [
        "sccm-sql01.contoso.com"
    ],
    "sql-reporting-server": [
        "sccm-ssrs01.contoso.com"
    ]
}
```

**Configure API Key:**
Replace `YOUR_API_KEY_HERE` in all `datadog.yaml` files with your actual Datadog API key.

### 2. Deployment Execution

Run the deployment script from an administrative PowerShell session:
```powershell
.\Deploy-DatadogConfigs.ps1
```

The script will:
- Validate prerequisites
- Create configuration backups
- Deploy role-specific configurations
- Restart Datadog Agent services
- Verify deployment success

### 3. Post-Installation Verification

**Check Agent Status:**
```powershell
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
```

**Verify Metrics in Datadog:**
- Navigate to Datadog dashboard
- Confirm metrics are being received from all servers
- Validate service checks are reporting correctly

**Test SQL Connectivity (SQL Servers):**
```powershell
Test-NetConnection -ComputerName <SQL_SERVER> -Port 1433
```

## Monitors and Widgets (Included)

- Service widgets per role: `check_status` targeting `windows_service.state`, grouped by `role` and `service_group`
- Log widgets per role: `log_stream` queries using normalized `channel` and `@evt.id`
- Monitor JSON per role (import if desired):
  - `distribution-point/distribution-point_monitor.json`
  - `management-point/management-point_monitor.json`
  - `site-server/site-server_monitor.json`
  - `sql-server/sql-server_monitor.json`
  - `sql-reporting-server/sql-reporting-server_monitor.json`

## Monitoring Configuration

### System Performance Monitoring
- CPU Usage: Warning >85%, Critical >95%
- Memory Usage: Warning >85%, Critical >95%
- Disk Space: Warning <15% free, Critical <10% free
- Network Utilization: Warning >70%, Critical >85%

### Service Monitoring
- Service Status: Critical if any monitored service is stopped
- System Resource Usage: Monitor via dashboard widgets for alerting

### SQL Server Performance
- Cache Hit Ratio: Warning <90%, Critical <85%
- Page Life Expectancy: Warning <300sec, Critical <180sec
- Blocked Processes: Warning >5, Critical >10

### Windows Event Log Monitoring
- System Events: Critical system events, service failures, DCOM errors
- Security Events: Authentication failures, privilege escalation, audit changes
- Application Events: SCCM-specific events, IIS errors, application crashes
- Operational Events: IIS operational logs, WDS events, PowerShell security

## Configuration Alignment Notes

- `windows_service.d` emits service checks (no metrics). Dashboards and monitors use the `windows_service.state` service check.
- Event inputs use `channel_path` and `"EventID"` matching rules; Datadog pipelines normalize to `channel` and `evt.id`, which are used in widgets/monitors.
- Legacy `process.d` is neutralized (`instances: []`) to avoid double collection. Process Agent handles process visibility.
- SQL Reporting Server now includes `wmi_check.d` for consistent host/IIS telemetry across roles.

## Security Implementation

### Windows Authentication Benefits
- No Stored Credentials: Eliminates SQL Server service account passwords
- Integrated Security: Leverages existing Windows security infrastructure
- Audit Trail: All database access logged through Windows authentication
- Compliance: Meets organizational security policy requirements

### Network Security
- Outbound HTTPS: All Datadog communication uses encrypted HTTPS
- No Inbound Connections: Agent initiates all connections to Datadog
- Firewall Configuration: Only outbound port 443 required

### Access Control
- Service Account Permissions: Datadog Agent service account limited to minimum required permissions
- SQL Server Access: Grant only necessary database read permissions
- File System Access: Restrict access to configuration files

## Troubleshooting

### Common Issues

**Agent Not Reporting Metrics:**
1. Verify API key is correct and has write permissions
2. Check network connectivity to Datadog endpoints
3. Review agent logs: `C:\ProgramData\Datadog\logs\agent.log`
4. Confirm agent service is running

**SQL Server Connection Issues:**
1. Verify Windows Authentication is enabled on SQL Server
2. Confirm Datadog Agent service account has SQL Server access
3. Test SQL connectivity from agent server
4. Check SQL Server logs for authentication errors

**Service Monitoring Issues:**
1. Verify service names match actual Windows service names
2. Check service permissions for monitoring account
3. Review Windows Event Logs for service-related errors
4. Validate WMI access permissions

**High Resource Usage:**
1. Adjust monitoring intervals in configuration files
2. Reduce number of monitored metrics if necessary
3. Consider dedicated monitoring server for large environments
4. Review and optimize custom queries

### Log Locations
- Datadog Agent Logs: `C:\ProgramData\Datadog\logs\`
- Deployment Script Logs: `_LOGS\` directory in script location
- Windows Event Logs: Event Viewer → Applications and Services Logs
- SQL Server Logs: SQL Server Management Studio → Management → SQL Server Logs

### Performance Optimization

**Agent Performance:**
- Monitor agent resource usage
- Adjust collection intervals based on environment size
- Use log processing rules to filter unnecessary events
- Consider agent proxy for large environments

**Network Optimization:**
- Implement agent proxy for bandwidth optimization
- Configure log compression
- Use metric aggregation where appropriate
- Monitor network utilization

## Advanced Configuration

### Custom Metrics
Add custom WMI queries or performance counters by modifying the `wmi_check.d` configurations:
```yaml
instances:
  - class: Win32_PerfRawData_PerfOS_System
    metrics:
      - [ProcessorQueueLength, system.proc.queue_length, gauge]
    tag_by: Name
```

### Alert Customization
Modify threshold values in `common/recommended-thresholds.yaml`:
```yaml
system_cpu_usage:
  warning: 80
  critical: 90
  
memory_usage:
  warning: 85
  critical: 95
```

### Dashboard Customization
Import and customize the provided dashboard templates:
- `dashboards/sccm-sql-applications.json`
- `dashboards/windows-server-health.json` (includes merged event widgets, per-role Event Log subsections, and standardized service widget titles)

Use Datadog's dashboard editor to modify widgets, add custom metrics, and adjust layouts.

## Maintenance

### Regular Tasks
- Weekly: Review alert notifications and adjust thresholds if needed
- Monthly: Validate service account permissions and review performance metrics
- Quarterly: Update monitoring configurations based on environment changes
- Annually: Update Datadog Agent to latest version and review security settings

### Configuration Updates
- Test changes in non-production environment first
- Use deployment script for consistent updates across servers
- Maintain configuration backups before making changes
- Document all customizations for future reference

### Backup and Recovery
- Regular backup of configuration files
- Document custom modifications
- Maintain deployment script version history
- Test recovery procedures periodically

## Support Resources

- Datadog Documentation: https://docs.datadoghq.com/
- SCCM Documentation: Microsoft System Center documentation
- Community Support: Datadog Community forums
- Professional Services: Datadog professional services for complex implementations

## Best Practices

### Deployment
- Always test in non-production environment first
- Use automated deployment script for consistency
- Maintain configuration version control
- Document environment-specific customizations

### Monitoring
- Start with default thresholds and adjust based on baseline
- Use tags consistently for filtering and organization
- Implement gradual alerting (warning before critical)
- Regular review and optimization of alert rules

### Security
- Regular review of service account permissions
- Monitor for unauthorized configuration changes
- Implement least-privilege access principles
- Regular security audits of monitoring infrastructure
