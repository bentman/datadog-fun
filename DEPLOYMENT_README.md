# SCCM Datadog Monitoring Deployment & Installation Guide

This guide provides comprehensive instructions for deploying and installing Datadog monitoring across your SCCM infrastructure, including both standard and Windows Authentication alternatives.

## 🔐 Important: Windows Authentication Alternatives

**If your organization has service account policy restrictions**, use the Windows Authentication deployment mode which eliminates the need for SQL Server service accounts by using Windows Authentication (`Trusted_Connection=yes`).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Methods](#deployment-methods)
3. [Automated Deployment](#automated-deployment)
4. [Manual Installation](#manual-installation)
5. [Server Role Configurations](#server-role-configurations)
6. [Post-Installation Verification](#post-installation-verification)
7. [Monitoring Thresholds](#monitoring-thresholds)
8. [Troubleshooting](#troubleshooting)

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
- WinRM enabled for remote deployment (automated deployment only)

### SQL Server Requirements

#### Standard Configuration
- SQL Server 2016 or later
- SQL Server authentication enabled
- Dedicated service account with appropriate permissions:
  - `db_datareader` on SCCM databases
  - `VIEW SERVER STATE` permission
  - Access to performance counters
- ODBC Driver 18 for SQL Server installed

#### Windows Authentication Alternative (for policy-restricted environments)
- SQL Server 2016 or later with Windows Authentication enabled
- Datadog Agent service account with SQL Server access permissions:
  - Windows Authentication login created for service account
  - `db_datareader` on SCCM databases
  - `VIEW SERVER STATE` permission
  - "Log on as a service" right
- ODBC Driver 18 for SQL Server installed
- **No dedicated SQL service account required**

### SCCM Environment Requirements
- SCCM Current Branch (version 1902 or later recommended)
- All SCCM server roles properly configured and operational
- Network connectivity between deployment machine and target servers

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

Use the unified `Deploy-DatadogConfigs.ps1` script for streamlined deployment across all servers.

### Method 2: Manual Installation

Step-by-step manual installation for environments requiring individual server configuration.

## Automated Deployment

### Quick Start

1. **Configure Target Servers**
   ```powershell
   # Edit servers.json with your actual server names
   notepad servers.json
   ```

2. **Choose Deployment Mode**

   #### Standard Deployment (with SQL Server service accounts)
   ```powershell
   # Test deployment first (recommended)
   .\Deploy-DatadogConfigs.ps1 -TestMode $true

   # Deploy configurations
   .\Deploy-DatadogConfigs.ps1
   ```

   #### Windows Authentication Deployment (no service accounts required)
   ```powershell
   # Test Windows Auth deployment first
   .\Deploy-DatadogConfigs.ps1 -UseWindowsAuth -TestMode $true

   # Deploy Windows Auth configurations
   .\Deploy-DatadogConfigs.ps1 -UseWindowsAuth
   ```

### Advanced Deployment Options

```powershell
# Deploy with custom server configuration file
.\Deploy-DatadogConfigs.ps1 -ServerConfig "production-servers.json"

# Deploy without creating backups
.\Deploy-DatadogConfigs.ps1 -BackupConfigs $false

# Deploy without restarting Datadog Agent service
.\Deploy-DatadogConfigs.ps1 -RestartService $false

# Deploy from custom configuration path
.\Deploy-DatadogConfigs.ps1 -ConfigPath "C:\Custom\Configs"

# Windows Auth deployment with custom options
.\Deploy-DatadogConfigs.ps1 -UseWindowsAuth -BackupConfigs $false -TestMode $true
```

### Server Configuration File (servers.json)

Create or modify `servers.json` with your server inventory:

```json
{
    "site-server": [
        "sccm-primary01.domain.com",
        "sccm-primary02.domain.com"
    ],
    "management-point": [
        "sccm-mp01.domain.com",
        "sccm-mp02.domain.com"
    ],
    "distribution-point": [
        "sccm-dp01.domain.com",
        "sccm-dp02.domain.com",
        "sccm-dp03.domain.com"
    ],
    "sql-server": [
        "sccm-sql01.domain.com"
    ],
    "sql-reporting-server": [
        "sccm-ssrs01.domain.com"
    ]
}
```

### Deployment Script Features

- **Unified functionality** for both standard and Windows Authentication deployments
- **Automatic backup creation** before deployment
- **Service restart** after configuration deployment
- **Comprehensive logging** with mode-specific log files:
  - Standard: `LOGS\Datadog_DeployConfigs-yyyyMMdd-HHmmss.log`
  - Windows Auth: `LOGS\Datadog_DeployConfigsAltAuth-yyyyMMdd-HHmmss.log`
- **Test mode** for validation without changes
- **Error handling** and rollback capabilities
- **Progress reporting** and deployment summary

## Manual Installation

### Pre-Installation Setup

1. **Install Datadog Agent** on each server:
   ```powershell
   # Download and install Datadog Agent
   # Run as Administrator
   msiexec /qn /i datadog-agent-7-latest.amd64.msi APIKEY="YOUR_DATADOG_API_KEY"
   ```

2. **Stop Datadog Agent Service**:
   ```powershell
   Stop-Service -Name "DatadogAgent"
   ```

3. **Create backup directory**:
   ```powershell
   $BackupDir = "C:\ProgramData\Datadog\backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   New-Item -Path $BackupDir -ItemType Directory -Force
   ```

### General Installation Process

#### Standard Configuration Installation
```powershell
# Backup existing configuration
Copy-Item "C:\ProgramData\Datadog\datadog.yaml" "$BackupDir\" -ErrorAction SilentlyContinue
Copy-Item "C:\ProgramData\Datadog\conf.d" "$BackupDir\" -Recurse -ErrorAction SilentlyContinue

# Copy role-specific configuration
Copy-Item "role-directory\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# For SQL Server roles: Update SQL credentials
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-username", "actual-sql-username"
$sqlConfig = $sqlConfig -replace "your-sql-password", "actual-sql-password"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Start service
Start-Service -Name "DatadogAgent"
```

#### 🔐 Windows Authentication Installation
```powershell
# Backup existing configuration
Copy-Item "C:\ProgramData\Datadog\datadog.yaml" "$BackupDir\" -ErrorAction SilentlyContinue
Copy-Item "C:\ProgramData\Datadog\conf.d" "$BackupDir\" -Recurse -ErrorAction SilentlyContinue

# Copy role-specific configuration
Copy-Item "role-directory\*" "C:\ProgramData\Datadog\" -Recurse -Force

# For SQL Server roles: Use Windows Authentication alternative
Copy-Item "role-directory\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Force

# Update API key only (no SQL credentials needed)
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Start service
Start-Service -Name "DatadogAgent"
```

## Server Role Configurations

### 1. Site Server Installation

#### Standard Installation
```powershell
# Copy configurations
Copy-Item "site-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent

# Verify SMS services
Get-Service SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER, SMS_NOTIFICATION_SERVER
```

**Monitored Components:**
- SCCM-specific services (SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER)
- IIS monitoring for SCCM web services
- Windows Event Log monitoring
- System performance metrics
- Process monitoring for SCCM components

### 2. Management Point Installation

#### Standard Installation
```powershell
# Copy configurations
Copy-Item "management-point\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent

# Verify IIS services
Get-Service W3SVC, IISADMIN
Import-Module WebAdministration
Get-Website
```

**Monitored Components:**
- Management Point services
- IIS monitoring for client communication
- Certificate monitoring
- Client connection metrics
- System performance monitoring

### 3. Distribution Point Installation

#### Standard Installation
```powershell
# Copy configurations
Copy-Item "distribution-point\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Restart service
Restart-Service DatadogAgent

# Verify WDS service (if PXE enabled)
Get-Service WDSServer -ErrorAction SilentlyContinue
```

**Monitored Components:**
- Distribution Point services
- Content library monitoring
- Network utilization tracking
- Disk space monitoring for content storage
- System performance metrics

### 4. SQL Server Installation

#### Standard SQL Server Installation
```powershell
# Copy configurations
Copy-Item "sql-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Update SQL Server configuration with credentials
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-username", "actual-sql-username"
$sqlConfig = $sqlConfig -replace "your-sql-password", "actual-sql-password"
$sqlConfig = $sqlConfig -replace "your-sql-server", "actual-sql-server-name"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent

# Verify SQL Server services
Get-Service MSSQLSERVER, SQLSERVERAGENT
```

#### 🔐 Windows Authentication SQL Server Installation
```powershell
# Copy configurations
Copy-Item "sql-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Use Windows Authentication alternative
Copy-Item "sql-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Force

# Update API key only (no SQL credentials needed)
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Update server name if needed
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-server", "actual-sql-server-name"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent

# Verify SQL Server services and Windows Authentication
Get-Service MSSQLSERVER, SQLSERVERAGENT
```

**Monitored Components (Both Standard and Windows Auth):**
- Database performance monitoring
- SCCM-specific database queries
- SQL Server service monitoring
- Transaction log monitoring
- Backup status monitoring
- Buffer cache hit ratio
- Connection count monitoring

### 5. SQL Reporting Server Installation

#### Standard SSRS Installation
```powershell
# Copy configurations
Copy-Item "sql-reporting-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Update API key
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Update SQL Server configuration with credentials
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-username", "actual-sql-username"
$sqlConfig = $sqlConfig -replace "your-sql-password", "actual-sql-password"
$sqlConfig = $sqlConfig -replace "your-sql-server", "actual-sql-server-name"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent

# Verify SSRS service
Get-Service ReportServer
```

#### 🔐 Windows Authentication SSRS Installation
```powershell
# Copy configurations
Copy-Item "sql-reporting-server\*" "C:\ProgramData\Datadog\" -Recurse -Force

# Use Windows Authentication alternative
Copy-Item "sql-reporting-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Force

# Update API key only (no SQL credentials needed)
(Get-Content "C:\ProgramData\Datadog\datadog.yaml") -replace "YOUR_API_KEY_HERE", "your-actual-api-key" | Set-Content "C:\ProgramData\Datadog\datadog.yaml"

# Update server name if needed
$sqlConfig = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
$sqlConfig = $sqlConfig -replace "your-sql-server", "actual-sql-server-name"
Set-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" $sqlConfig

# Restart service
Restart-Service DatadogAgent

# Verify SSRS service and Windows Authentication
Get-Service ReportServer
```

**Monitored Components (Both Standard and Windows Auth):**
- SQL Server Reporting Services monitoring
- Report execution metrics
- Database connectivity monitoring
- Service health monitoring

## Post-Installation Verification

### 1. Check Agent Status
```powershell
# Verify Datadog Agent is running
Get-Service DatadogAgent

# Check agent status and configuration
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status

# Check specific integration status
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status | Select-String "sqlserver\|windows_service\|wmi_check"
```

### 2. Verify Metrics Collection

#### Standard Metrics Verification
1. Navigate to Datadog Metrics Explorer
2. Search for `sccm.*` metrics
3. Verify metrics are being collected from your SCCM hosts
4. Check for SQL Server metrics: `sqlserver.*`
5. Confirm system metrics: `system.cpu.*`, `system.mem.*`, `system.disk.*`

#### Windows Authentication Metrics Verification
1. Navigate to Datadog Metrics Explorer
2. Search for `sccm.*` metrics with `auth:windows` tag
3. Verify SQL Server metrics are being collected: `sqlserver.*`
4. Confirm no authentication errors in agent logs
5. Check for Windows Auth specific tags in metric metadata

### 3. Log Verification
```powershell
# Check Datadog Agent logs for errors
Get-Content "C:\ProgramData\Datadog\logs\agent.log" -Tail 50

# Check for SQL Server integration logs
Get-Content "C:\ProgramData\Datadog\logs\sqlserver.log" -Tail 20 -ErrorAction SilentlyContinue

# For Windows Auth deployments, verify no authentication errors
Get-Content "C:\ProgramData\Datadog\logs\agent.log" | Select-String "auth\|sql\|connection\|trusted"

# Check integration-specific logs
Get-ChildItem "C:\ProgramData\Datadog\logs\" -Filter "*.log" | ForEach-Object {
    Write-Host "=== $($_.Name) ==="
    Get-Content $_.FullName -Tail 5
}
```

### 4. Dashboard and Alert Setup
```powershell
# Import SCCM monitoring dashboards to your Datadog account
# Use the JSON files in the dashboards/ directory

# For Windows Auth deployments, use alternative dashboards
# dashboards/sccm-sql-server-health.json.alt
# widgets/sccm-sql-server-widgets.xml.alt
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
- **Component Status**: Warning for any component in warning state

### SQL Server (Both Standard and Windows Auth)
- **Connection Count**: Warning at 80% of max connections, Critical at 95%
- **Database Size**: Warning at 80% of allocated space, Critical at 90%
- **Transaction Log**: Warning at 70% full, Critical at 85% full
- **Buffer Cache Hit Ratio**: Warning below 90%, Critical below 85%
- **Page Life Expectancy**: Warning below 300 seconds, Critical below 180 seconds

### Windows Event Logs
- **Critical Events**: Immediate alert for any critical system events
- **Error Events**: Warning for application errors, Critical for system errors
- **Security Events**: Alert on failed login attempts and privilege escalations

## Troubleshooting

### Common Issues

#### 1. Agent Not Starting
```powershell
# Check Windows Event Logs
Get-EventLog -LogName Application -Source "Datadog Agent" -Newest 10

# Verify configuration syntax
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" configcheck

# Check for port conflicts
netstat -an | Select-String ":8125\|:8126"

# Verify API key
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status | Select-String "API Key"
```

#### 2. SQL Server Connection Issues

##### Standard Configuration
```powershell
# Test SQL connectivity manually
sqlcmd -S "server-name" -U "username" -P "password" -Q "SELECT @@VERSION"

# Verify SQL Server authentication mode
sqlcmd -S "server-name" -U "username" -P "password" -Q "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly')"

# Check ODBC Driver installation
Get-ItemProperty HKLM:\SOFTWARE\ODBC\ODBCINST.INI\* | Where-Object {$_.PSChildName -like "*SQL Server*"}

# Test ODBC connection
$connectionString = "Driver={ODBC Driver 18 for SQL Server};Server=server-name;Database=master;UID=username;PWD=password;"
$connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
try {
    $connection.Open()
    Write-Host "Connection successful"
    $connection.Close()
} catch {
    Write-Host "Connection failed: $($_.Exception.Message)"
}
```

##### Windows Authentication Configuration
```powershell
# Test Windows Authentication connectivity
sqlcmd -S "server-name" -E -Q "SELECT @@VERSION"

# Verify service account has SQL access
sqlcmd -S "server-name" -E -Q "SELECT SYSTEM_USER, USER_NAME()"

# Check Windows Authentication is enabled
sqlcmd -S "server-name" -E -Q "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly')"

# Test ODBC connection with Windows Auth
$connectionString = "Driver={ODBC Driver 18 for SQL Server};Server=server-name;Database=master;Trusted_Connection=yes;"
$connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
try {
    $connection.Open()
    Write-Host "Windows Authentication connection successful"
    $connection.Close()
} catch {
    Write-Host "Windows Authentication connection failed: $($_.Exception.Message)"
}

# Verify service account permissions
whoami /priv
whoami /groups
```

#### 3. Missing Metrics
```powershell
# Check specific integration status
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status

# Review integration logs
Get-Content "C:\ProgramData\Datadog\logs\*.log" | Select-String "ERROR\|WARN"

# Test individual checks
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check sqlserver
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check windows_service
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" check wmi_check
```

#### 4. Windows Authentication Specific Issues

##### Authentication Failures
```powershell
# Check service account configuration
Get-WmiObject -Class Win32_Service -Filter "Name='DatadogAgent'" | Select-Object StartName

# Verify "Log on as a service" right
secedit /export /cfg temp_security.cfg
Get-Content temp_security.cfg | Select-String "SeServiceLogonRight"
Remove-Item temp_security.cfg

# Test SQL Server Windows Authentication
sqlcmd -S "server-name" -E -Q "SELECT SYSTEM_USER, IS_SRVROLEMEMBER('sysadmin')"
```

##### Missing Metrics with Windows Auth
```powershell
# Check for Windows Auth specific errors
Get-Content "C:\ProgramData\Datadog\logs\agent.log" | Select-String "trusted\|windows\|auth" -Context 2

# Verify simplified queries are working
sqlcmd -S "server-name" -E -Q "SELECT name FROM sys.databases"
sqlcmd -S "server-name" -E -Q "SELECT counter_name, cntr_value FROM sys.dm_os_performance_counters WHERE counter_name LIKE '%Buffer cache hit ratio%'"

# Check permissions for basic queries
sqlcmd -S "server-name" -E -Q "SELECT HAS_PERMS_BY_NAME(NULL, NULL, 'VIEW SERVER STATE')"
```

#### 5. Service Account Issues
```powershell
# For Windows Auth: Verify service account setup
$service = Get-WmiObject -Class Win32_Service -Filter "Name='DatadogAgent'"
Write-Host "Service runs as: $($service.StartName)"

# Check if service account has required permissions
$account = $service.StartName
if ($account -ne "LocalSystem") {
    # Check SQL Server access
    sqlcmd -S "server-name" -E -Q "SELECT name FROM sys.server_principals WHERE name = '$account'"
    
    # Check database permissions
    sqlcmd -S "server-name" -E -Q "SELECT dp.permission_name, dp.state_desc FROM sys.database_permissions dp JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id WHERE pr.name = '$account'"
}
```

### Log Locations
- **Agent Logs**: `C:\ProgramData\Datadog\logs\agent.log`
- **Integration Logs**: `C:\ProgramData\Datadog\logs\`
- **Deployment Logs**: `LOGS\Datadog_DeployConfigs*.log`
- **Windows Event Logs**: Application and System logs for Datadog Agent events

### Performance Optimization

#### For Standard Configurations
- Monitor SQL Server connection pool usage
- Optimize custom query frequency
- Review metric collection intervals

#### For Windows Authentication Configurations
- Monitor Windows Authentication overhead
- Optimize simplified query performance
- Review service account permission scope

### Support Resources
- **Datadog Documentation**: https://docs.datadoghq.com/
- **SCCM Documentation**: https://docs.microsoft.com/en-us/mem/configmgr/
- **SQL Server Documentation**: https://docs.microsoft.com/en-us/sql/
- **Windows Authentication**: https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/

## Security Considerations

### Standard Configuration
- Store SQL Server credentials securely using encrypted configuration files
- Use dedicated service accounts with minimal required permissions
- Regularly rotate service account passwords
- Monitor service account usage and access patterns
- Implement network segmentation for database access

### Windows Authentication Alternative
- **Benefits**: 
  - No stored credentials in configuration files
  - Uses existing Windows security infrastructure
  - Reduces credential management overhead
  - Complies with service account restriction policies
- **Requirements**: 
  - Proper service account configuration with SQL Server access
  - Windows Authentication enabled on SQL Server
  - Service account with "Log on as a service" right
- **Monitoring**: 
  - Use `auth:windows` tag to identify Windows Auth deployments
  - Monitor authentication success/failure rates
  - Review service account access patterns

### General Security Best Practices
- Regularly update Datadog Agent to latest version
- Monitor agent logs for security-related events
- Implement least-privilege access principles
- Use encrypted communication channels
- Regular security audits of monitoring infrastructure

## Maintenance and Updates

### Regular Maintenance Tasks
1. **Monitor deployment logs** for errors or warnings
2. **Review metrics collection** to ensure all expected data is flowing
3. **Update configurations** as SCCM environment changes
4. **Test backup and restore procedures** periodically
5. **Review and update monitoring thresholds** based on environment performance
6. **Rotate credentials** (standard configuration only)
7. **Audit service account permissions** (Windows Auth configuration)

### Update Procedures
1. **Test changes** in non-production environment first
2. **Backup existing configurations** before updates
3. **Deploy changes** during maintenance windows
4. **Verify metrics and logs** collection after changes
5. **Update dashboards and alerts** as needed
6. **Document changes** and update runbooks

### Scaling Considerations
- Plan for additional SCCM servers and roles
- Monitor Datadog Agent resource usage
- Consider metric retention and storage requirements
- Plan for disaster recovery scenarios
- Document configuration management procedures

This comprehensive deployment and installation guide ensures successful implementation of Datadog monitoring across your SCCM infrastructure while providing flexibility for different authentication requirements and security policies.