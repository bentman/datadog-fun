# Windows Authentication Alternative Files Summary

This document provides a complete list of all files created for the Windows Authentication alternative configuration for SQL Server monitoring in SCCM environments.

## Created Files

### 1. Core Configuration Files

#### SQL Server Configuration
- **File**: `sql-server/conf.d/sqlserver.d/conf.yaml.alt`
- **Purpose**: Alternative SQL Server configuration using Windows Authentication
- **Key Features**:
  - Uses `Trusted_Connection=yes` instead of username/password
  - DBM disabled for simplified permissions
  - Basic custom queries for SCCM monitoring
  - Essential performance counters only
  - SQL Server error log collection

#### SQL Reporting Server Configuration  
- **File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt`
- **Purpose**: Alternative SSRS configuration using Windows Authentication
- **Key Features**:
  - Windows Authentication for SSRS database monitoring
  - Simplified ReportServer database checks
  - SSRS log collection maintained
  - Basic SQL Server health monitoring

### 2. Dashboard and Widget Alternatives

#### Dashboard Configuration
- **File**: `dashboards/sccm-sql-server-health.json.alt`
- **Purpose**: Alternative dashboard with Windows Authentication context
- **Key Features**:
  - Updated queries with `auth:windows` tag filter
  - Configuration notes and documentation
  - Essential SQL Server performance metrics
  - Windows Authentication specific styling and notes

#### Widget Configuration
- **File**: `widgets/sccm-sql-server-widgets.xml.alt`
- **Purpose**: Alternative widgets with Windows Authentication support
- **Key Features**:
  - Updated metric queries with Windows Auth tags
  - Configuration documentation within widgets
  - Essential performance monitoring widgets
  - Windows Authentication specific notes

### 3. Deployment and Documentation

#### Enhanced Deployment Script
- **File**: `Deploy-DatadogConfigs-WindowsAuth.ps1`
- **Purpose**: PowerShell deployment script with Windows Authentication support
- **Key Features**:
  - `-UseWindowsAuth` parameter for alternative deployment
  - Automatic handling of `.alt` configuration files
  - Backup and rollback capabilities
  - Windows Authentication specific validation
  - Dashboard and widget deployment guidance

#### Comprehensive Documentation
- **File**: `WINDOWS_AUTH_ALTERNATIVE_README.md`
- **Purpose**: Complete guide for Windows Authentication alternative
- **Key Features**:
  - Installation and setup instructions
  - Configuration differences explanation
  - Troubleshooting guide
  - Security considerations
  - Migration procedures

#### Files Summary Document
- **File**: `WINDOWS_AUTH_FILES_SUMMARY.md` (this file)
- **Purpose**: Complete inventory of all alternative configuration files

## File Relationships

```
datadog-fun/
├── sql-server/
│   └── conf.d/
│       └── sqlserver.d/
│           ├── conf.yaml (original)
│           └── conf.yaml.alt (Windows Auth alternative)
├── sql-reporting-server/
│   └── conf.d/
│       └── sqlserver.d/
│           ├── conf.yaml (original)
│           └── conf.yaml.alt (Windows Auth alternative)
├── dashboards/
│   ├── sccm-sql-server-health.json (original)
│   └── sccm-sql-server-health.json.alt (Windows Auth alternative)
├── widgets/
│   ├── sccm-sql-server-widgets.xml (original)
│   └── sccm-sql-server-widgets.xml.alt (Windows Auth alternative)
├── Deploy-DatadogConfigs.ps1 (original)
├── Deploy-DatadogConfigs-WindowsAuth.ps1 (enhanced with Windows Auth support)
├── WINDOWS_AUTH_ALTERNATIVE_README.md (comprehensive documentation)
└── WINDOWS_AUTH_FILES_SUMMARY.md (this summary)
```

## Usage Scenarios

### Scenario 1: New Deployment with Windows Authentication
1. Use `Deploy-DatadogConfigs-WindowsAuth.ps1 -UseWindowsAuth $true`
2. Import alternative dashboard and widgets
3. Follow setup instructions in README

### Scenario 2: Migration from Standard to Windows Authentication
1. Backup existing configurations
2. Deploy alternative configurations using deployment script
3. Update dashboards and widgets
4. Validate metrics collection

### Scenario 3: Rollback to Standard Configuration
1. Use backup configurations created during deployment
2. Restore original dashboard and widgets
3. Configure SQL Server authentication
4. Restart Datadog Agent

## Key Differences from Standard Configuration

| Component | Standard | Windows Auth Alternative |
|-----------|----------|-------------------------|
| Authentication | SQL Server Auth (username/password) | Windows Auth (Trusted_Connection=yes) |
| DBM Features | Enabled | Disabled |
| Custom Queries | Complex SCCM queries | Simplified basic queries |
| Permissions | Extensive SQL permissions | Basic Windows authentication |
| Service Account | Required | Not required |
| Dashboard Tags | `role:sccm-sql-server` | `role:sccm-sql-server,auth:windows` |

## Validation Checklist

After deploying Windows Authentication alternatives:

### Configuration Validation
- [ ] Agent connects to SQL Server without username/password
- [ ] Basic SQL Server metrics are collected
- [ ] Log collection is working
- [ ] Custom queries execute successfully

### Metrics Validation
- [ ] `sqlserver.buffer.cache_hit_ratio{auth:windows}` available
- [ ] `sqlserver.stats.connections{auth:windows}` available
- [ ] `sqlserver.memory.*{auth:windows}` metrics available
- [ ] Custom query metrics appearing in Datadog

### Dashboard Validation
- [ ] Alternative dashboard displays data correctly
- [ ] Widgets show metrics with Windows Auth tags
- [ ] No authentication errors in visualizations

### Log Validation
- [ ] SQL Server error logs appearing in Datadog
- [ ] SSRS logs collected (for reporting server)
- [ ] Log processing rules working correctly

## Maintenance and Updates

### Regular Tasks
- Monitor Agent logs for authentication issues
- Verify metric collection continues after SQL Server updates
- Update log file paths if SQL Server versions change
- Review and update custom queries as needed

### When to Update
- SQL Server version upgrades
- Windows security policy changes
- Datadog Agent updates
- SCCM version changes
- Performance monitoring requirements changes

## Support Information

### Troubleshooting Resources
1. `WINDOWS_AUTH_ALTERNATIVE_README.md` - Comprehensive troubleshooting guide
2. Datadog Agent logs - Check for authentication and connection issues
3. Windows Event Logs - Review for authentication failures
4. SQL Server logs - Verify connection attempts and permissions

### Common Issues and Solutions
- **Authentication failures**: Verify Windows Authentication enabled on SQL Server
- **Missing metrics**: Check Agent service account permissions
- **Log collection issues**: Verify file paths and read permissions
- **Dashboard not showing data**: Confirm `auth:windows` tag is being applied

## Security Considerations

### Benefits of Windows Authentication
- No stored credentials in configuration files
- Leverages existing Windows security infrastructure
- Complies with service account restriction policies
- Reduces credential management overhead

### Security Best Practices
- Use dedicated service account for Datadog Agent
- Apply principle of least privilege for SQL Server access
- Regularly review Windows permissions
- Monitor for authentication failures
- Keep security patches current

## Contact and Escalation

For issues with Windows Authentication alternative configurations:
1. Review troubleshooting section in README
2. Check Datadog Agent and Windows Event logs
3. Verify SQL Server Windows Authentication settings
4. Contact system administrator for permission issues
5. Escalate to Datadog support for integration-specific problems