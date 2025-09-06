# SCCM Datadog Monitoring Configuration Package

This package contains comprehensive Datadog monitoring configurations for Microsoft System Center Configuration Manager (SCCM) servers running in Azure environments.

## Overview

This monitoring solution provides:

- **System Performance Monitoring**: CPU, RAM, disk space, and network metrics with industry-standard thresholds
- **SCCM Service Monitoring**: Critical SCCM services including SMS_EXECUTIVE, Site Component Manager, and Notification Server
- **SQL Server Health Monitoring**: Database performance, SCCM-specific queries, and SQL Server health metrics
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
│       ├── win32_event_log.d/
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
├── sql-reporting-server/           # SQL Reporting Services server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       ├── sqlserver.d/
│       └── iis.d/
├── common/                         # Shared configuration files
│   ├── system-probe.yaml
│   └── recommended-thresholds.yaml
├── INSTALLATION_GUIDE.md           # Detailed installation instructions
└── README.md                       # This file
```

## Server Role Configurations

### 1. Site Server Configuration
**Purpose**: Monitors the primary SCCM site server
**Key Components**:
- SMS_EXECUTIVE service monitoring
- SMS_SITE_COMPONENT_MANAGER monitoring
- SMS_NOTIFICATION_SERVER monitoring
- SCCM-specific Windows event logs
- System performance metrics

### 2. Management Point Configuration
**Purpose**: Monitors SCCM Management Point servers
**Key Components**:
- IIS performance monitoring
- Client communication metrics
- WMI performance counters
- ASP.NET application monitoring
- Authentication event monitoring

### 3. Distribution Point Configuration
**Purpose**: Monitors SCCM Distribution Point servers
**Key Components**:
- Content distribution monitoring
- Storage and network performance
- IIS monitoring for content delivery
- PXE service monitoring (if enabled)
- WDS service monitoring

### 4. SQL Server Configuration
**Purpose**: Monitors SQL Server hosting SCCM database
**Key Components**:
- SQL Server performance counters
- SCCM database health metrics
- Custom queries for SCCM client counts
- Site status monitoring
- Database size and growth monitoring

### 5. SQL Reporting Server Configuration
**Purpose**: Monitors SQL Server Reporting Services (SSRS)
**Key Components**:
- SSRS service monitoring
- Report execution statistics
- ReportServer database monitoring
- IIS monitoring for Report Manager
- Report performance metrics

## Monitoring Capabilities

### System Metrics
- **CPU Utilization**: Warning at 75%, Critical at 85%
- **Memory Usage**: Warning at 80%, Critical at 90%
- **Disk Space**: Warning at 80%, Critical at 90%
- **Network Performance**: Bandwidth utilization and packet loss
- **Disk Performance**: Queue length and latency monitoring

### SCCM-Specific Metrics
- **Client Count**: Active SCCM clients
- **Site Component Status**: Health of SCCM components
- **Service Availability**: Critical SCCM services
- **Content Distribution**: Distribution point health
- **Database Performance**: SCCM database metrics

### SQL Server Metrics
- **Buffer Cache Hit Ratio**: Warning <90%, Critical <85%
- **Page Life Expectancy**: Warning <300s, Critical <180s
- **Blocked Processes**: Warning >5, Critical >10
- **Database Growth**: Monitoring space utilization
- **Query Performance**: Slow query detection

### Event Log Monitoring
- **System Events**: Critical and error events
- **Application Events**: SCCM and SQL Server events
- **Security Events**: Authentication failures
- **IIS Events**: Web server errors and warnings

## Quick Start

1. **Prerequisites**: Ensure you have a Datadog account and API key
2. **Download**: Extract this package to your SCCM servers
3. **Install**: Follow the detailed instructions in `INSTALLATION_GUIDE.md`
4. **Configure**: Update configuration files with your environment details
5. **Deploy**: Install Datadog Agent and deploy configurations
6. **Verify**: Check Datadog dashboard for incoming metrics

## Recommended Thresholds

The `common/recommended-thresholds.yaml` file contains industry-standard monitoring thresholds based on:
- Microsoft SCCM best practices
- SQL Server performance guidelines
- Windows Server monitoring standards
- Azure infrastructure recommendations



## Security Considerations

- **Monitoring Accounts**: Use dedicated accounts with minimal required permissions
- **Password Management**: Implement strong passwords and regular rotation
- **Network Security**: Ensure secure communication to Datadog endpoints
- **Access Control**: Limit configuration file access to authorized personnel

## Maintenance

### Regular Tasks
- **Monthly**: Review thresholds and update as needed
- **Quarterly**: Update monitoring account credentials
- **Annually**: Review overall monitoring strategy and coverage

### Updates
- Monitor for Datadog Agent updates
- Review SCCM version compatibility
- Update configurations for new SCCM features

## Support and Troubleshooting

### Common Issues
- **Agent connectivity**: Verify outbound HTTPS (port 443) access
- **SQL permissions**: Ensure monitoring user has proper database access
- **WMI access**: Verify WMI service is running and accessible
- **Event log access**: Confirm agent has permission to read event logs

### Log Locations
- **Datadog Agent**: `C:\ProgramData\Datadog\logs\`
- **SCCM Logs**: `C:\Program Files\Microsoft Configuration Manager\Logs\`
- **SQL Server Logs**: Available through SQL Server Management Studio
- **Windows Event Logs**: Event Viewer

### Performance Tuning
- Adjust check intervals in configuration files
- Modify `check_runners` in datadog.yaml for resource optimization
- Disable unnecessary integrations for specific server roles

## License and Support

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Support

This SCCM Datadog monitoring package is provided as-is under the MIT License. While we strive to maintain and improve these configurations, please note:

- **Community Support**: Issues and questions can be submitted via GitHub Issues
- **Contributions**: Pull requests and improvements are welcome
- **Datadog Support**: For Datadog Agent-specific issues, refer to [official Datadog documentation](https://docs.datadoghq.com/) and support channels
- **SCCM Support**: For SCCM-related questions, consult [Microsoft documentation](https://docs.microsoft.com/en-us/mem/configmgr/) and community resources

### Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. Users are responsible for testing configurations in non-production environments before deployment.

---

**Note**: Always test configurations in a non-production environment before deploying to production SCCM infrastructure.