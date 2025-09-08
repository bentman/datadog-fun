# Windows Authentication Alternative Configuration

This document describes the alternative SQL Server monitoring configurations that use Windows Authentication instead of username/password authentication, designed for environments where service accounts cannot be used due to policy restrictions.

## Overview

The alternative configurations provide essential SQL Server monitoring capabilities while using Windows Authentication (`Trusted_Connection=yes`) instead of SQL Server authentication. This approach is suitable for organizations with security policies that restrict the use of service accounts for monitoring purposes.

## Alternative Configuration Files

### 1. SQL Server Configuration
- **File**: `sql-server/conf.d/sqlserver.d/conf.yaml.alt`
- **Purpose**: Main SCCM SQL Server database monitoring
- **Authentication**: Windows Authentication (Trusted_Connection)
- **Features**: Basic SQL Server performance monitoring, log collection, simplified custom queries

### 2. SQL Reporting Server Configuration  
- **File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt`
- **Purpose**: SCCM SQL Server Reporting Services monitoring
- **Authentication**: Windows Authentication (Trusted_Connection)
- **Features**: SSRS monitoring, basic database checks, log collection

### 3. Dashboard Configuration
- **File**: `dashboards/sccm-sql-server-health.json.alt`
- **Purpose**: Alternative dashboard with Windows Authentication context
- **Features**: Updated queries with `auth:windows` tag, configuration notes

### 4. Widget Configuration
- **File**: `widgets/sccm-sql-server-widgets.xml.alt`
- **Purpose**: Alternative widgets with Windows Authentication context
- **Features**: Updated queries, configuration documentation

## Key Differences from Standard Configuration

| Feature | Standard Config | Windows Auth Alternative |
|---------|----------------|-------------------------|
| Authentication | Username/Password | Windows Authentication (Trusted_Connection=yes) |
| Database Monitoring (DBM) | Enabled | Disabled (reduces permission requirements) |
| Custom Queries | Complex SCCM queries | Simplified queries using basic permissions |
| Performance Counters | Full set | Essential counters only |
| Permissions Required | Extensive SQL permissions | Basic Windows authentication |
| Service Account | Required | Not required |

## Available Metrics

The alternative configuration provides the following essential metrics:

### SQL Server Performance Counters
- `sqlserver.buffer.cache_hit_ratio` - Buffer cache hit ratio
- `sqlserver.buffer.page_life_expectancy` - Page life expectancy
- `sqlserver.memory.total_server_memory` - Total server memory
- `sqlserver.memory.target_server_memory` - Target server memory
- `sqlserver.stats.connections` - Active connections
- `sqlserver.stats.processes_blocked` - Blocked processes

### Custom Metrics (Simplified)
- Basic database file count monitoring
- SQL Server version and health information
- ReportServer database basic checks (for reporting server)

### Log Collection
- SQL Server error logs (ERRORLOG)
- SQL Server Agent logs (SQLAGENT.OUT)
- SSRS logs (ReportServerService*.log, ReportServerWebApp*.log)

## Installation and Setup

### Prerequisites
1. Datadog Agent installed on SQL Server host
2. Windows Authentication enabled on SQL Server
3. Agent service running under an account with appropriate Windows permissions

### Step 1: Backup Existing Configuration
```powershell
# Backup current configurations
Copy-Item "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml.backup"
```

### Step 2: Deploy Alternative Configuration

#### Option A: Using Combined Deployment Script (Recommended)
```powershell
# Deploy Windows Authentication alternatives to all configured servers
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Test deployment without making changes
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true

# Deploy without creating backups
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -BackupConfigs $false
```

#### Option B: Manual Deployment
```powershell
# Copy alternative configuration
Copy-Item "sql-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"

# For reporting server (if applicable)
Copy-Item "sql-reporting-server\conf.d\sqlserver.d\conf.yaml.alt" "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml"
```

#### Option C: Using Windows Auth Specific Script
```powershell
# Deploy using the Windows Authentication specific script
.\Deploy-DatadogConfigs-WindowsAuth.ps1 -UseWindowsAuth $true
```

### Step 3: Configure Windows Permissions
Ensure the Datadog Agent service account has:
- Log on as a service right
- Access to SQL Server via Windows Authentication
- Read access to SQL Server log files

### Step 4: Restart Datadog Agent
```powershell
Restart-Service DatadogAgent
```

### Step 5: Verify Configuration
```powershell
# Check agent status
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
```

## Validation

### Check Metrics Collection
1. Navigate to Datadog Metrics Explorer
2. Search for `sqlserver.*` metrics with `auth:windows` tag
3. Verify metrics are being collected from your SQL Server hosts

### Expected Metrics
- `sqlserver.buffer.cache_hit_ratio{auth:windows,role:sccm-sql-server}`
- `sqlserver.stats.connections{auth:windows,role:sccm-sql-server}`
- `sqlserver.memory.total_server_memory{auth:windows,role:sccm-sql-server}`

### Check Log Collection
1. Navigate to Datadog Logs
2. Search for `source:sqlserver` with `auth:windows` tag
3. Verify SQL Server error logs are being collected

## Troubleshooting

### Common Issues

#### 1. Authentication Failures
**Symptom**: Agent cannot connect to SQL Server
**Solution**: 
- Verify Windows Authentication is enabled on SQL Server
- Check that Agent service account has SQL Server login permissions
- Ensure `Trusted_Connection=yes` is properly configured

#### 2. Missing Metrics
**Symptom**: Some metrics not appearing in Datadog
**Solution**:
- Check Agent logs for permission errors
- Verify SQL Server performance counters are enabled
- Confirm Agent service account has necessary Windows permissions

#### 3. Log Collection Issues
**Symptom**: SQL Server logs not appearing in Datadog
**Solution**:
- Verify log file paths are correct for your SQL Server version
- Check Agent service account has read access to log files
- Confirm log processing rules are working

### Log Locations by SQL Server Version
- **SQL Server 2019**: `C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\`
- **SQL Server 2017**: `C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Log\`
- **SQL Server 2016**: `C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log\`

## Limitations

### Reduced Functionality
- Database Monitoring (DBM) features disabled
- Advanced query performance metrics not available
- Detailed blocking and wait statistics limited
- Custom SCCM queries simplified

### Workarounds
- Use log-based monitoring for detailed troubleshooting
- Implement custom queries that work with basic permissions
- Leverage Windows Performance Counters for additional metrics
- Use SQL Server Management Studio for detailed analysis when needed

## Migration Back to Standard Configuration

To revert to the standard configuration:

1. Stop Datadog Agent
2. Restore backup configuration file
3. Configure SQL Server authentication and service account
4. Update dashboard and widget configurations
5. Restart Datadog Agent

## Support and Maintenance

### Regular Tasks
- Monitor Agent logs for authentication issues
- Verify log file paths after SQL Server updates
- Update configurations when SQL Server versions change
- Review metric collection and adjust thresholds as needed

### Updates
When updating this configuration:
1. Test changes in non-production environment
2. Backup existing configuration
3. Deploy changes during maintenance window
4. Verify metrics and logs collection
5. Update dashboards and alerts as needed

## Security Considerations

### Benefits
- No stored credentials in configuration files
- Uses existing Windows security infrastructure
- Reduces credential management overhead
- Complies with service account restriction policies

### Best Practices
- Use dedicated service account for Datadog Agent
- Apply principle of least privilege
- Regularly review Windows permissions
- Monitor for authentication failures
- Keep SQL Server and Windows security patches current

## Contact and Support

For issues with this configuration:
1. Check Datadog Agent logs
2. Verify SQL Server connectivity and permissions
3. Review Windows Event Logs for authentication issues
4. Consult Datadog documentation for SQL Server integration
5. Contact your system administrator for Windows permission issues