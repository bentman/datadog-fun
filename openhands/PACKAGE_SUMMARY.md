# SCCM Datadog Monitoring Package Summary

## Package Overview

This comprehensive monitoring package provides Datadog configurations for all SCCM server roles running in Azure environments. The package includes role-specific configurations, monitoring thresholds, and detailed installation instructions.

## Complete File Structure

```
sccm-datadog-configs/
├── README.md                                    # Package overview and quick start
├── INSTALLATION_GUIDE.md                       # Detailed installation instructions
├── PACKAGE_SUMMARY.md                          # This summary file
│
├── common/                                      # Shared configuration files
│   ├── system-probe.yaml                       # Network performance monitoring config
│   └── recommended-thresholds.yaml             # Industry-standard monitoring thresholds
│
├── site-server/                                 # SCCM Primary Site Server
│   ├── datadog.yaml                            # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # SCCM services monitoring
│       ├── win32_event_log.d/conf.yaml         # Windows/SCCM event logs
│       ├── wmi_check.d/conf.yaml               # System performance via WMI
│       └── process.d/conf.yaml                 # Critical process monitoring
│
├── management-point/                            # SCCM Management Point
│   ├── datadog.yaml                            # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # IIS and MP services
│       ├── win32_event_log.d/conf.yaml         # IIS/WMI/Security event logs
│       ├── wmi_check.d/conf.yaml               # System + IIS performance
│       ├── process.d/conf.yaml                 # IIS worker processes
│       └── iis.d/conf.yaml                     # IIS-specific monitoring
│
├── distribution-point/                          # SCCM Distribution Point
│   ├── datadog.yaml                            # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # IIS, WDS, DP services
│       ├── win32_event_log.d/conf.yaml         # IIS/WDS/SCCM event logs
│       ├── wmi_check.d/conf.yaml               # Storage/network focused metrics
│       └── process.d/conf.yaml                 # IIS and WDS processes
│
├── sql-server/                                  # SCCM SQL Database Server
│   ├── datadog.yaml                            # Main agent configuration (with DBM)
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # SQL Server services
│       ├── win32_event_log.d/conf.yaml         # SQL Server event logs
│       ├── wmi_check.d/conf.yaml               # SQL performance counters
│       ├── process.d/conf.yaml                 # SQL Server processes
│       └── sqlserver.d/conf.yaml               # SQL Server + SCCM queries
│
└── sql-reporting-server/                        # SQL Reporting Services
    ├── datadog.yaml                            # Main agent configuration (with DBM)
    └── conf.d/
        ├── windows_service.d/conf.yaml         # SSRS and related services
        ├── win32_event_log.d/conf.yaml         # SSRS/IIS event logs
        ├── process.d/conf.yaml                 # SSRS processes
        └── sqlserver.d/conf.yaml               # SSRS database monitoring
```

## Monitoring Coverage by Server Role

### Site Server Monitoring
- **Services**: SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER, SMS_NOTIFICATION_SERVER, IIS, WMI, BITS, WinRM
- **Processes**: smsexec.exe, w3wp.exe, wmiprvse.exe
- **Event Logs**: System errors, SCCM application events, Security authentication failures
- **Performance**: CPU, Memory, Disk, Network, System queues

### Management Point Monitoring
- **Services**: IIS (W3SVC, IISADMIN), WMI, BITS, WinRM, SMS_MP_CONTROL_MANAGER
- **Processes**: IIS worker processes, WMI providers, IIS admin
- **Event Logs**: IIS operational logs, WMI activity, SCCM events, Security events
- **Performance**: System metrics + IIS connections, requests, ASP.NET performance

### Distribution Point Monitoring
- **Services**: IIS, WMI, BITS, WinRM, WDS (if PXE), TFTP, SMS_DP_MONITOR
- **Processes**: IIS workers, WMI providers, WDS server
- **Event Logs**: IIS logs, WDS operational logs, SCCM events
- **Performance**: System metrics + enhanced disk/network monitoring for content distribution

### SQL Server Monitoring
- **Services**: MSSQLSERVER, SQLSERVERAGENT, SQLBrowser, SQLWriter, WMI, WinRM, MSDTC
- **Processes**: sqlservr.exe, sqlagent.exe, WMI providers
- **Event Logs**: SQL Server engine logs, SQL Agent logs, SCCM database events
- **Performance**: System metrics + SQL buffer manager, memory manager, general statistics
- **Custom Queries**: SCCM client count, site status, database size monitoring

### SQL Reporting Server Monitoring
- **Services**: ReportServer, MSSQLSERVER (if local), SQLSERVERAGENT, IIS, WMI, WinRM
- **Processes**: ReportingServicesService.exe, IIS workers, SQL processes
- **Event Logs**: SSRS logs, IIS logs, SQL Server logs
- **Performance**: System + SQL metrics
- **Custom Queries**: Report execution statistics, ReportServer database monitoring

## Key Features

### System Performance Monitoring
- **CPU Utilization**: Warning 75%, Critical 85%
- **Memory Usage**: Warning 80%, Critical 90%
- **Disk Space**: Warning 80%, Critical 90%
- **Disk Performance**: Queue length and latency monitoring
- **Network Performance**: Bandwidth utilization and packet monitoring

### SCCM-Specific Monitoring
- **Service Health**: All critical SCCM services with automatic restart detection
- **Client Metrics**: Active client count and health status
- **Site Component Status**: Real-time component health monitoring
- **Content Distribution**: Distribution point health and content status
- **Database Health**: SCCM database performance and growth monitoring

### SQL Server Health Monitoring
- **Performance Counters**: Buffer cache hit ratio, page life expectancy, blocked processes
- **Database Monitoring**: Size, growth, fragmentation, and performance
- **Query Performance**: Slow query detection and analysis
- **Connection Monitoring**: User connections and blocking sessions

### Windows Event Log Monitoring
- **System Events**: Critical and error events from System log
- **Application Events**: SCCM, SQL Server, IIS, and SSRS events
- **Security Events**: Authentication failures and security violations
- **Operational Logs**: Service-specific operational event logs

### Network Performance Monitoring
- **Connection Tracking**: Network connections and performance
- **Service Dependencies**: Inter-service communication monitoring
- **Bandwidth Utilization**: Network interface performance
- **Packet Analysis**: Packet loss and network errors

## Deployment Recommendations

### Pre-Deployment
1. Review `common/recommended-thresholds.yaml` for environment-specific adjustments
2. Create dedicated SQL monitoring accounts with appropriate permissions
3. Verify network connectivity to Datadog endpoints
4. Test configurations in non-production environment

### Deployment Order
1. **SQL Server** - Deploy database monitoring first
2. **Site Server** - Core SCCM infrastructure
3. **Management Points** - Client communication infrastructure
4. **Distribution Points** - Content distribution infrastructure
5. **SQL Reporting Server** - Reporting infrastructure

### Post-Deployment
1. Verify all integrations are reporting metrics
2. Create Datadog dashboards for SCCM overview
3. Configure alerting based on recommended thresholds
4. Set up notification channels for critical alerts

## Customization Options

### Threshold Adjustments
- Modify thresholds in individual configuration files
- Adjust check intervals for performance optimization
- Enable/disable specific integrations based on requirements

### Additional Monitoring
- Add custom WMI classes for specific metrics
- Include additional Windows event log channels
- Extend SQL queries for custom SCCM metrics
- Add application-specific monitoring for custom SCCM extensions

### Performance Tuning
- Adjust `check_runners` in datadog.yaml for resource optimization
- Modify collection intervals for high-frequency metrics
- Disable unnecessary integrations for specific server roles

## Support and Maintenance

### Regular Maintenance Tasks
- **Weekly**: Review alert notifications and adjust thresholds
- **Monthly**: Check for Datadog Agent updates and integration improvements
- **Quarterly**: Review monitoring coverage and add new metrics as needed
- **Annually**: Conduct comprehensive monitoring strategy review

### Troubleshooting Resources
- Detailed troubleshooting section in INSTALLATION_GUIDE.md
- Log locations and analysis procedures
- Common issue resolution steps
- Performance optimization guidelines

This package provides enterprise-grade monitoring for SCCM environments with comprehensive coverage of all critical components and services.