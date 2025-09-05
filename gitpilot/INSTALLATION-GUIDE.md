# Datadog Configuration Installation Guide for SCCM Infrastructure

## Overview
This guide provides step-by-step instructions for installing and configuring Datadog monitoring for SCCM servers running in Azure.

## Pre-Installation Requirements

### 1. Prerequisites
- Administrative access to all SCCM servers
- Datadog account with API key
- Windows PowerShell 5.1 or higher
- Network connectivity to Datadog endpoints
- SQL Server authentication credentials (for SQL monitoring)

### 2. Firewall Requirements
Ensure outbound HTTPS (443) access to:
- `api.datadoghq.com`
- `app.datadoghq.com`
- `intake.logs.datadoghq.com`

## Installation Steps

### Step 1: Download and Install Datadog Agent

Run PowerShell as Administrator on each server:

```powershell
# Download Datadog Agent installer
Start-BitsTransfer -Source https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi -Destination C:\temp\datadog-agent.msi

# Install Datadog Agent (replace YOUR_API_KEY with actual key)
msiexec /i C:\temp\datadog-agent.msi APIKEY="YOUR_API_KEY" SITE="datadoghq.com" /qn
```

### Step 2: Stop Datadog Agent Service

```powershell
Stop-Service -Name "DatadogAgent" -Force
```

### Step 3: Deploy Configuration Files

Based on the server role, copy the appropriate configuration files:

#### For Site Server:
```powershell
Copy-Item -Path ".\site-server\*" -Destination "C:\ProgramData\Datadog\" -Recurse -Force
```

#### For Management Point:
```powershell
Copy-Item -Path ".\management-point\*" -Destination "C:\ProgramData\Datadog\" -Recurse -Force
```

#### For Distribution Point:
```powershell
Copy-Item -Path ".\distribution-point\*" -Destination "C:\ProgramData\Datadog\" -Recurse -Force
```

#### For SQL Server (SCCM Database):
```powershell
Copy-Item -Path ".\sql-sccm-database\*" -Destination "C:\ProgramData\Datadog\" -Recurse -Force
```

#### For SQL Reporting Server:
```powershell
Copy-Item -Path ".\sql-reporting-server\*" -Destination "C:\ProgramData\Datadog\" -Recurse -Force
```

### Step 4: Configure SQL Server Monitoring (SQL Servers Only)

1. Create monitoring user in SQL Server Management Studio:

```sql
-- Create login
CREATE LOGIN datadog_monitor WITH PASSWORD = 'StrongP@ssw0rd123!';
GO

-- Create user in master database
USE master;
CREATE USER datadog_monitor FOR LOGIN datadog_monitor;
GO

-- Grant necessary permissions
GRANT VIEW SERVER STATE TO datadog_monitor;
GRANT VIEW ANY DEFINITION TO datadog_monitor;
GO

-- For SCCM database monitoring
USE CM_PS1;  -- Replace with your SCCM database name
CREATE USER datadog_monitor FOR LOGIN datadog_monitor;
GRANT SELECT TO datadog_monitor;
GO
```

2. Update SQL password in configuration:
   - Edit `C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml`
   - Replace `YOUR_PASSWORD_HERE` with the actual password
   - Update database name if different from `CM_PS1`

### Step 5: Update Configuration Values

1. Update API Key in all `datadog.yaml` files:
   ```powershell
   $apiKey = "YOUR_ACTUAL_API_KEY"
   $configFile = "C:\ProgramData\Datadog\datadog.yaml"
   (Get-Content $configFile) -replace 'YOUR_API_KEY_HERE', $apiKey | Set-Content $configFile
   ```

2. Update hostname to match actual server name:
   ```powershell
   $hostname = $env:COMPUTERNAME
   (Get-Content $configFile) -replace 'sccm-.*-server', $hostname | Set-Content $configFile
   ```

### Step 6: Start Datadog Agent

```powershell
Start-Service -Name "DatadogAgent"
```

### Step 7: Verify Installation

1. Check agent status:
   ```powershell
   & "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
   ```

2. Check configuration:
   ```powershell
   & "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" configcheck
   ```

3. View agent logs:
   ```powershell
   Get-Content "C:\ProgramData\Datadog\logs\agent.log" -Tail 50
   ```

## Post-Installation Configuration

### 1. Configure Monitors in Datadog UI

1. Log into Datadog web interface
2. Navigate to **Monitors → New Monitor**
3. Create the following monitors:

#### CPU Monitor:
- Type: Metric
- Metric: `system.cpu.user`
- Alert condition: Above 80% for 5 minutes (Warning), Above 95% for 5 minutes (Critical)

#### Memory Monitor:
- Type: Metric
- Metric: `system.mem.used` / `system.mem.total` * 100
- Alert condition: Above 85% (Warning), Above 95% (Critical)

#### Disk Space Monitor:
- Type: Metric
- Metric: `system.disk.used` / `system.disk.total` * 100
- Alert condition: Above 80% (Warning), Above 90% (Critical)

#### Service Monitors:
- Type: Service Check
- Check: `windows_service.state`
- Alert condition: Any service not in "running" state

### 2. Create Dashboards

1. Navigate to **Dashboards → New Dashboard**
2. Create dashboards for:
   - SCCM Infrastructure Overview
   - SQL Server Performance
   - Site Server Health
   - Distribution Points Status

### 3. Configure Notifications

1. Navigate to **Integrations**
2. Set up notification channels:
   - Email
   - Slack/Teams (optional)
   - ServiceNow (optional)

## Troubleshooting

### Common Issues

1. **Agent not starting:**
   - Check Windows Event Log
   - Verify API key is correct
   - Check firewall/proxy settings

2. **No metrics appearing:**
   - Verify agent is running: `Get-Service DatadogAgent`
   - Check agent logs for errors
   - Confirm network connectivity

3. **SQL metrics not collecting:**
   - Verify SQL login works
   - Check SQL Server port (1433)
   - Confirm permissions granted

4. **Missing logs:**
   - Verify log paths exist
   - Check file permissions
   - Confirm Windows Event Log access

### Support Resources

- Datadog Documentation: https://docs.datadoghq.com/
- SCCM Monitoring Best Practices: https://docs.microsoft.com/en-us/mem/configmgr/
- Contact Datadog Support: support@datadoghq.com

## Maintenance

### Weekly Tasks:
- Review alert notifications
- Check dashboard health
- Verify all agents reporting

### Monthly Tasks:
- Review and tune alert thresholds
- Update agent version if needed
- Archive old logs

### Quarterly Tasks:
- Review monitoring coverage
- Update documentation
- Performance baseline review