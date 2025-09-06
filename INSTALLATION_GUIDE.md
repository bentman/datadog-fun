# SCCM Datadog Monitoring Installation Guide

This guide provides step-by-step instructions for deploying Datadog monitoring across your SCCM infrastructure running in Azure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Installation Setup](#pre-installation-setup)
3. [Server Role Configurations](#server-role-configurations)
4. [Installation Steps by Server Role](#installation-steps-by-server-role)
5. [Post-Installation Verification](#post-installation-verification)
6. [Monitoring Thresholds](#monitoring-thresholds)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Datadog Account Requirements
- Active Datadog account with appropriate licensing
- Datadog API key with write permissions
- Access to Datadog dashboard and alerting features

### Windows Server Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrator privileges on all SCCM servers
- Network connectivity to Datadog endpoints (outbound HTTPS on port 443)

### SQL Server Requirements (for database servers)
- SQL Server 2016 or later
- SQL Server authentication enabled
- Dedicated monitoring user account with appropriate permissions

### SCCM Environment Requirements
- SCCM Current Branch (version 1902 or later recommended)
- Functional SCCM hierarchy with identified server roles
- Network connectivity between all SCCM servers

## Pre-Installation Setup

### 1. Create Datadog Monitoring User for SQL Server

Run the following SQL script on your SCCM SQL Server and SQL Reporting Server:

```sql
-- Create monitoring user
CREATE LOGIN [datadog_monitoring_user] WITH PASSWORD = 'YourSecurePassword123!';
CREATE USER [datadog_monitoring_user] FOR LOGIN [datadog_monitoring_user];

-- Grant necessary permissions
GRANT SELECT ON sys.dm_os_performance_counters TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_os_wait_stats TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_os_memory_clerks TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_exec_query_stats TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_exec_procedure_stats TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_exec_requests TO [datadog_monitoring_user];
GRANT SELECT ON sys.dm_exec_sessions TO [datadog_monitoring_user];
GRANT SELECT ON sys.database_files TO [datadog_monitoring_user];
GRANT VIEW SERVER STATE TO [datadog_monitoring_user];
GRANT VIEW DATABASE STATE TO [datadog_monitoring_user];

-- SCCM-specific permissions
USE [CM_YourSiteCode];  -- Replace with your SCCM database name
GRANT SELECT ON v_R_System TO [datadog_monitoring_user];
GRANT SELECT ON v_ComponentSummarizer TO [datadog_monitoring_user];

-- SSRS-specific permissions (for Reporting Server)
USE [ReportServer];
GRANT SELECT ON dbo.ExecutionLog3 TO [datadog_monitoring_user];
USE [ReportServerTempDB];
GRANT SELECT ON sys.database_files TO [datadog_monitoring_user];
```

### 2. Download Datadog Agent

Download the latest Datadog Agent for Windows from:
https://app.datadoghq.com/account/settings#agent/windows

### 3. Prepare Configuration Files

Extract the provided configuration files to a temporary location on each server.

## Server Role Configurations

### Available Configurations

1. **Site Server** (`site-server/`)
   - Primary site server monitoring
   - SMS services monitoring
   - SCCM-specific event logs

2. **Management Point** (`management-point/`)
   - IIS performance monitoring
   - Client communication metrics
   - WMI performance counters

3. **Distribution Point** (`distribution-point/`)
   - Content distribution monitoring
   - Storage and network metrics
   - PXE service monitoring (if enabled)

4. **SQL Server** (`sql-server/`)
   - SCCM database monitoring
   - SQL Server performance metrics
   - Custom SCCM queries

5. **SQL Reporting Server** (`sql-reporting-server/`)
   - SSRS service monitoring
   - Report execution metrics
   - Reporting database monitoring

## Installation Steps by Server Role

### General Installation Process

1. **Install Datadog Agent**
   ```powershell
   # Run as Administrator
   msiexec /qn /i datadog-agent-7-latest.amd64.msi APIKEY="YOUR_DATADOG_API_KEY"
   ```

2. **Stop Datadog Agent Service**
   ```powershell
   Stop-Service -Name "DatadogAgent"
   ```

3. **Deploy Configuration Files**
   ```powershell
   # Copy main configuration
   Copy-Item "datadog.yaml" "C:\ProgramData\Datadog\datadog.yaml" -Force
   
   # Copy integration configurations
   Copy-Item "conf.d\*" "C:\ProgramData\Datadog\conf.d\" -Recurse -Force
   
   # Copy system probe configuration (if applicable)
   Copy-Item "..\common\system-probe.yaml" "C:\ProgramData\Datadog\system-probe.yaml" -Force
   ```

4. **Update Configuration Files**
   - Replace `YOUR_DATADOG_API_KEY` with your actual API key
   - Replace `YOUR_SCCM_*_HOSTNAME` with actual server hostnames
   - Update SQL Server passwords and connection strings
   - Adjust file paths if different from defaults

5. **Start Datadog Agent Service**
   ```powershell
   Start-Service -Name "DatadogAgent"
   ```

### Site Server Specific Steps

1. Follow general installation process using `site-server/` configuration
2. Verify SMS services are running:
   ```powershell
   Get-Service SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER, SMS_NOTIFICATION_SERVER
   ```
3. Check SCCM console for component status

### Management Point Specific Steps

1. Follow general installation process using `management-point/` configuration
2. Verify IIS is running and configured:
   ```powershell
   Get-Service W3SVC, IISADMIN
   Import-Module WebAdministration
   Get-Website
   ```
3. Test Management Point functionality from SCCM console

### Distribution Point Specific Steps

1. Follow general installation process using `distribution-point/` configuration
2. If PXE is enabled, verify WDS service:
   ```powershell
   Get-Service WDSServer
   ```
3. Check content distribution status in SCCM console

### SQL Server Specific Steps

1. Follow general installation process using `sql-server/` configuration
2. Update SQL connection details in `conf.d/sqlserver.d/conf.yaml`:
   ```yaml
   instances:
     - host: localhost,1433
       username: datadog_monitoring_user
       password: YourSecurePassword123!
   ```
3. Verify SQL Server services:
   ```powershell
   Get-Service MSSQLSERVER, SQLSERVERAGENT
   ```

### SQL Reporting Server Specific Steps

1. Follow general installation process using `sql-reporting-server/` configuration
2. Update SQL connection details and log paths
3. Verify SSRS service:
   ```powershell
   Get-Service ReportServer
   ```
4. Test report manager accessibility

## Post-Installation Verification

### 1. Check Agent Status
```powershell
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
```

### 2. Verify Integration Status
```powershell
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check windows_service
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check wmi_check
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check win32_event_log
```

### 3. Check Datadog Dashboard
- Log into Datadog web interface
- Navigate to Infrastructure → Host Map
- Verify all servers are reporting
- Check for any integration errors

### 4. Validate Metrics Collection
- Go to Metrics → Explorer
- Search for SCCM-specific metrics:
  - `system.cpu.pct_processor_time`
  - `system.mem.available`
  - `system.disk.pct_free_space`
  - `sqlserver.buffer.cache_hit_ratio` (SQL servers)
  - `iis.current_connections` (Management/Distribution Points)

## Monitoring Thresholds

Refer to `common/recommended-thresholds.yaml` for detailed threshold recommendations.

### Key Thresholds Summary

| Metric | Warning | Critical |
|--------|---------|----------|
| CPU Utilization | 75% | 85% |
| Memory Utilization | 80% | 90% |
| Disk Space | 80% | 90% |
| SQL Buffer Cache Hit Ratio | <90% | <85% |
| IIS Current Connections | >1000 | >2000 |

### Creating Datadog Monitors

1. Navigate to Monitors → New Monitor
2. Select metric type
3. Configure thresholds based on recommendations
4. Set up notification channels
5. Test alert functionality

## Troubleshooting

### Common Issues

#### Agent Not Starting
```powershell
# Check Windows Event Log
Get-EventLog -LogName Application -Source "Datadog Agent" -Newest 10

# Check agent logs
Get-Content "C:\ProgramData\Datadog\logs\agent.log" -Tail 50
```

#### SQL Server Connection Issues
```powershell
# Test SQL connectivity
sqlcmd -S localhost -U datadog_monitoring_user -P YourPassword -Q "SELECT @@VERSION"

# Check SQL Server logs
Get-EventLog -LogName Application -Source "MSSQLSERVER" -Newest 10
```

#### Missing Metrics
1. Verify integration configuration files are in correct location
2. Check integration status: `agent.exe check <integration_name>`
3. Review agent logs for errors
4. Validate WMI classes exist: `Get-WmiObject -Class Win32_PerfRawData_PerfOS_System`

#### High Agent Resource Usage
1. Reduce check frequency in configuration files
2. Disable unnecessary integrations
3. Adjust `check_runners` in datadog.yaml
4. Monitor agent performance metrics

### Log Locations

- **Agent Logs**: `C:\ProgramData\Datadog\logs\`
- **Windows Event Logs**: Event Viewer → Applications and Services Logs
- **SQL Server Logs**: SQL Server Management Studio → Management → SQL Server Logs
- **IIS Logs**: `C:\inetpub\logs\LogFiles\`
- **SCCM Logs**: `C:\Program Files\Microsoft Configuration Manager\Logs\`

### Support Resources

- Datadog Documentation: https://docs.datadoghq.com/
- SCCM Documentation: https://docs.microsoft.com/en-us/mem/configmgr/
- Community Forums: https://community.datadoghq.com/

## Security Considerations

1. **Credential Management**
   - Use strong passwords for monitoring accounts
   - Consider using Windows Authentication where possible
   - Regularly rotate monitoring account passwords

2. **Network Security**
   - Ensure Datadog endpoints are accessible through firewalls
   - Monitor for unusual network traffic patterns
   - Implement network segmentation best practices

3. **Access Control**
   - Limit monitoring account permissions to minimum required
   - Regularly audit account access and permissions
   - Monitor for unauthorized access attempts

## Maintenance

### Regular Tasks

1. **Monthly**
   - Review monitoring thresholds and adjust as needed
   - Check for Datadog Agent updates
   - Validate all integrations are functioning

2. **Quarterly**
   - Review and update monitoring account passwords
   - Assess monitoring coverage and add new metrics if needed
   - Performance tune agent configuration

3. **Annually**
   - Review overall monitoring strategy
   - Update documentation
   - Conduct disaster recovery testing

---

For additional support or questions, please refer to the Datadog documentation or contact your system administrator.