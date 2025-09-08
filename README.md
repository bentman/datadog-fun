# SCCM Datadog Monitoring Configuration Package

This package contains comprehensive Datadog monitoring configurations for Microsoft System Center Configuration Manager (SCCM) servers running in Azure environments.

## 🔐 Important: Windows Authentication Alternatives Available

**If your organization has service account policy restrictions**, this package includes Windows Authentication alternative configurations (`.alt` files) that eliminate the need for SQL Server service accounts. These alternatives use Windows Authentication (`Trusted_Connection=yes`) instead of username/password authentication.

**Key Alternative Files:**
- `sql-server/conf.d/sqlserver.d/conf.yaml.alt` - SQL Server Windows Auth config
- `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt` - SSRS Windows Auth config

See the [SQL Server Configuration](#sql-server-configuration) sections below for deployment details.

## Overview

This monitoring solution provides:

- **System Performance Monitoring**: CPU, RAM, disk space, and network metrics with industry-standard thresholds
- **SCCM Service Monitoring**: Critical SCCM services including SMS_EXECUTIVE, Site Component Manager, and Notification Server
- **SQL Server Health Monitoring**: Database performance, SCCM-specific queries, and SQL Server health metrics (with Windows Auth alternatives)
- **Windows Event Log Monitoring**: Critical system, application, and security events
- **Role-Specific Monitoring**: Tailored configurations for each SCCM server role

## Package Structure

```
sccm-datadog-configs/
├── site-server/                    # SCCM Primary Site Server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── iis.d/
├── management-point/               # Management Point server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── iis.d/
├── distribution-point/             # Distribution Point server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── iis.d/
├── sql-server/                     # SCCM SQL Database server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── sqlserver.d/
│           ├── conf.yaml           # Standard SQL Server config
│           └── conf.yaml.alt       # Windows Auth alternative
├── sql-reporting-server/           # SQL Reporting Services server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── sqlserver.d/
│           ├── conf.yaml           # Standard SSRS config
│           └── conf.yaml.alt       # Windows Auth alternative
├── dashboards/                     # Datadog dashboard configurations
├── widgets/                        # Datadog widget configurations
├── Deploy-DatadogConfigs-Combined.ps1  # Unified deployment script
├── servers.json                    # Server role configuration template
└── LOGS/                          # Deployment logs directory
```

## Quick Start

### 1. Configure Target Servers
```powershell
# Edit servers.json with your actual server names
notepad servers.json
```

### 2. Choose Deployment Method

#### Standard Deployment (with SQL Server service accounts)
```powershell
# Test deployment first (recommended)
.\Deploy-DatadogConfigs-Combined.ps1 -TestMode $true

# Deploy configurations
.\Deploy-DatadogConfigs-Combined.ps1
```

#### Windows Authentication Deployment (no service accounts required)
```powershell
# Test Windows Auth deployment first
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true

# Deploy Windows Auth configurations
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth
```

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
- WinRM enabled for remote deployment

### SQL Server Requirements

#### Standard Configuration
- SQL Server 2016 or later
- SQL Server authentication enabled
- Dedicated service account with appropriate permissions
- ODBC Driver 18 for SQL Server installed

#### Windows Authentication Alternative (for policy-restricted environments)
- SQL Server 2016 or later with Windows Authentication enabled
- Datadog Agent service account with SQL Server access permissions
- ODBC Driver 18 for SQL Server installed
- No dedicated SQL service account required

## Server Role Configurations

### Site Server
**Primary SCCM site server monitoring**
- SCCM-specific services (SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER)
- IIS monitoring for SCCM web services
- Windows Event Log monitoring
- System performance metrics
- Process monitoring for SCCM components

### Management Point
**SCCM Management Point server monitoring**
- Management Point services
- IIS monitoring for client communication
- Certificate monitoring
- Client connection metrics
- System performance monitoring

### Distribution Point
**SCCM Distribution Point server monitoring**
- Distribution Point services
- Content library monitoring
- Network utilization tracking
- Disk space monitoring for content storage
- System performance metrics

### SQL Server Configuration

#### Standard SQL Server Monitoring
**For environments with SQL Server service accounts**
- Database performance monitoring
- SCCM-specific database queries
- SQL Server service monitoring
- Transaction log monitoring
- Backup status monitoring

**Configuration File**: `sql-server/conf.d/sqlserver.d/conf.yaml`

#### 🔐 Windows Authentication Alternative
**For environments with service account policy restrictions**
- Essential SQL Server performance monitoring using Windows Authentication
- Simplified SCCM database queries with basic permissions
- No service account credentials required
- Uses `Trusted_Connection=yes` for authentication

**Configuration File**: `sql-server/conf.d/sqlserver.d/conf.yaml.alt`

**To use Windows Authentication alternative:**
```powershell
# Deploy using the combined script
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Or manually copy the alternative configuration
Copy-Item "sql-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
```

### SQL Reporting Server Configuration

#### Standard SSRS Monitoring
**For environments with SQL Server service accounts**
- SQL Server Reporting Services monitoring
- Report execution metrics
- Database connectivity monitoring
- Service health monitoring

**Configuration File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml`

#### 🔐 Windows Authentication Alternative
**For environments with service account policy restrictions**
- Essential SSRS monitoring using Windows Authentication
- Basic database connectivity checks
- No service account credentials required

**Configuration File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt`

**To use Windows Authentication alternative:**
```powershell
# Deploy using the combined script
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Or manually copy the alternative configuration
Copy-Item "sql-reporting-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
```

## Deployment Options

### Automated Deployment (Recommended)

The `Deploy-DatadogConfigs-Combined.ps1` script provides unified deployment functionality:

```powershell
# Standard deployment with service accounts
.\Deploy-DatadogConfigs-Combined.ps1

# Windows Authentication deployment (no service accounts)
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Test mode (validation without deployment)
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true

# Deploy without creating backups
.\Deploy-DatadogConfigs-Combined.ps1 -BackupConfigs $false

# Deploy without restarting Datadog Agent
.\Deploy-DatadogConfigs-Combined.ps1 -RestartService $false
```

**Script Features:**
- Unified functionality for both standard and Windows Auth deployments
- Automatic backup creation before deployment
- Service restart after configuration deployment
- Comprehensive logging with mode-specific log files
- Test mode for validation without changes
- Error handling and rollback capabilities

**Log Files:**
- Standard deployment: `LOGS\Datadog_DeployConfigs-yyyyMMdd-HHmmss.log`
- Windows Auth deployment: `LOGS\Datadog_DeployConfigsAltAuth-yyyyMMdd-HHmmss.log`

### Manual Deployment

For environments requiring manual deployment:

1. **Backup existing configurations**
2. **Copy role-specific configurations** to target servers
3. **Update datadog.yaml** with your API key
4. **Restart Datadog Agent service**
5. **Verify metrics collection**

## Installation Steps by Server Role

### 1. Site Server Installation
```powershell
# Copy configurations
Copy-Item "site-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent
```

### 2. Management Point Installation
```powershell
# Copy configurations
Copy-Item "management-point\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent
```

### 3. Distribution Point Installation
```powershell
# Copy configurations
Copy-Item "distribution-point\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent
```

### 4. SQL Server Installation

#### Standard SQL Server Installation
```powershell
# Copy configurations
Copy-Item "sql-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key and SQL credentials
$config = Get-Content "C:\ProgramData\Datadog\datadog.yaml"
$config = $config -replace "YOUR_API_KEY_HERE", "your-actual-api-key"
Set-Content "C:\ProgramData\Datadog\datadog.yaml" $config

# Update SQL Server configuration with credentials
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-username", "actual-sql-username"
$sqlConfig = $sqlConfig -replace "your-sql-password", "actual-sql-password"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent
```

#### 🔐 Windows Authentication SQL Server Installation
```powershell
# Copy configurations
Copy-Item "sql-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Use Windows Authentication alternative
Copy-Item "sql-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Force

# Update API key only (no SQL credentials needed)
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent
```

### 5. SQL Reporting Server Installation

#### Standard SSRS Installation
```powershell
# Copy configurations
Copy-Item "sql-reporting-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key and SQL credentials
$config = Get-Content "C:\ProgramData\Datadog\datadog.yaml"
$config = $config -replace "YOUR_API_KEY_HERE", "your-actual-api-key"
Set-Content "C:\ProgramData\Datadog\datadog.yaml" $config

# Update SQL Server configuration with credentials
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-username", "actual-sql-username"
$sqlConfig = $sqlConfig -replace "your-sql-password", "actual-sql-password"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent
```

#### 🔐 Windows Authentication SSRS Installation
```powershell
# Copy configurations
Copy-Item "sql-reporting-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Use Windows Authentication alternative
Copy-Item "sql-reporting-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Force

# Update API key only (no SQL credentials needed)
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent
```

## Post-Installation Verification

### 1. Check Agent Status
```powershell
# Verify Datadog Agent is running
Get-Service DatadogAgent

# Check agent status and configuration
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
```

### 2. Verify Metrics Collection

#### Standard Metrics Verification
1. Navigate to Datadog Metrics Explorer
2. Search for `sccm.*` metrics
3. Verify metrics are being collected from your SCCM hosts
4. Check for SQL Server metrics: `sqlserver.*`

#### Windows Authentication Metrics Verification
1. Navigate to Datadog Metrics Explorer
2. Search for `sccm.*` metrics with `auth:windows` tag
3. Verify SQL Server metrics are being collected: `sqlserver.*`
4. Confirm no authentication errors in agent logs

### 3. Dashboard Import
```powershell
# Import SCCM monitoring dashboards to your Datadog account
# Use the JSON files in the dashboards/ directory
```

### 4. Log Verification
```powershell
# Check Datadog Agent logs for errors
Get-Content "C:\ProgramData\Datadog\logs\agent.log" -Tail 50

# For Windows Auth deployments, verify no authentication errors
Get-Content "C:\ProgramData\Datadog\logs\agent.log" | Select-String "auth\|sql\|connection"
```

## Monitoring Thresholds

### System Performance
- **CPU Usage**: Warning at 80%, Critical at 90%
- **Memory Usage**: Warning at 85%, Critical at 95%
- **Disk Space**: Warning at 80% full, Critical at 90% full
- **Network Utilization**: Warning at 80%, Critical at 90%

### SCCM Services
- **Service Status**: Critical if any monitored service is stopped
- **Response Time**: Warning at 5 seconds, Critical at 10 seconds

### SQL Server (Both Standard and Windows Auth)
- **Connection Count**: Warning at 80% of max, Critical at 95%
- **Database Size**: Warning at 80% of allocated space
- **Transaction Log**: Warning at 70% full, Critical at 85%
- **Buffer Cache Hit Ratio**: Warning below 90%, Critical below 85%

## Troubleshooting

### Common Issues

#### 1. Agent Not Starting
```powershell
# Check Windows Event Logs
Get-EventLog -LogName Application -Source "Datadog Agent" -Newest 10

# Verify configuration syntax
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" configcheck
```

#### 2. SQL Server Connection Issues

##### Standard Configuration
- Verify SQL Server authentication is enabled
- Check service account permissions
- Confirm ODBC Driver 18 is installed
- Test SQL connectivity manually

##### Windows Authentication Configuration
- Verify Datadog Agent service account has SQL Server access
- Check Windows Authentication is enabled on SQL Server
- Confirm service account has "Log on as a service" right
- Test Windows Authentication connectivity

#### 3. Missing Metrics
```powershell
# Check specific integration status
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status

# Review integration logs
Get-Content "C:\ProgramData\Datadog\logs\*.log" | Select-String "ERROR\|WARN"
```

#### 4. Windows Authentication Specific Issues
- **Authentication Failures**: Check service account permissions and SQL Server Windows Authentication settings
- **Missing Metrics**: Verify simplified queries are working with basic SQL permissions
- **Service Account Issues**: Ensure Datadog Agent runs under account with SQL Server access

### Log Locations
- **Agent Logs**: `C:\ProgramData\Datadog\logs\agent.log`
- **Integration Logs**: `C:\ProgramData\Datadog\logs\`
- **Deployment Logs**: `LOGS\Datadog_DeployConfigs*.log`

### Support Resources
- Datadog Documentation: https://docs.datadoghq.com/
- SCCM Documentation: https://docs.microsoft.com/en-us/mem/configmgr/
- SQL Server Documentation: https://docs.microsoft.com/en-us/sql/

## Security Considerations

### Standard Configuration
- Store SQL Server credentials securely
- Use dedicated service accounts with minimal permissions
- Regularly rotate service account passwords
- Monitor service account usage

### Windows Authentication Alternative
- **Benefits**: No stored credentials, uses existing Windows security infrastructure
- **Requirements**: Proper service account configuration and SQL Server permissions
- **Compliance**: Suitable for environments with service account policy restrictions
- **Monitoring**: Use `auth:windows` tag to identify Windows Auth deployments

## Maintenance

### Regular Tasks
1. **Monitor deployment logs** for errors or warnings
2. **Review metrics collection** to ensure all expected data is flowing
3. **Update configurations** as SCCM environment changes
4. **Test backup and restore procedures** periodically
5. **Review and update monitoring thresholds** based on environment changes

### Updates and Changes
1. **Test changes** in non-production environment first
2. **Backup existing configurations** before updates
3. **Deploy changes** during maintenance windows
4. **Verify metrics and logs** collection after changes
5. **Update dashboards and alerts** as needed

This comprehensive monitoring solution ensures complete visibility into your SCCM infrastructure while providing flexibility for different authentication requirements and security policies.