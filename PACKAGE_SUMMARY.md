# SCCM Datadog Monitoring Package Summary

## Package Overview

This comprehensive monitoring package provides Datadog configurations for all SCCM server roles running in Azure environments. The package includes role-specific configurations, monitoring thresholds, detailed installation instructions, and **Windows Authentication alternatives** for environments with service account policy restrictions.

## 🔐 Windows Authentication Alternatives

**Important**: This package includes Windows Authentication alternative configurations (`.alt` files) that eliminate the need for SQL Server service accounts, using Windows Authentication (`Trusted_Connection=yes`) instead of username/password authentication.

**Alternative Files Available:**
- `sql-server/conf.d/sqlserver.d/conf.yaml.alt` - SQL Server Windows Auth config
- `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt` - SSRS Windows Auth config
- `dashboards/sccm-sql-server-health.json.alt` - Alternative dashboard
- `widgets/sccm-sql-server-widgets.xml.alt` - Alternative widgets

## Complete File Structure

```
sccm-datadog-configs/
├── README.md                                    # Package overview and quick start guide
├── DEPLOYMENT_README.md                         # Comprehensive deployment & installation guide
├── PACKAGE_SUMMARY.md                          # This summary file
│
├── Deploy-DatadogConfigs-Combined.ps1          # Unified deployment script
├── servers.json                                # Server role configuration template
├── LOGS/                                       # Deployment logs directory
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
│       ├── process.d/conf.yaml                 # Critical process monitoring
│       └── iis.d/conf.yaml                     # IIS-specific monitoring
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
│       ├── process.d/conf.yaml                 # IIS and WDS processes
│       └── iis.d/conf.yaml                     # IIS-specific monitoring
│
├── sql-server/                                  # SCCM SQL Database Server
│   ├── datadog.yaml                            # Main agent configuration (with DBM)
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # SQL Server services
│       ├── win32_event_log.d/conf.yaml         # SQL Server event logs
│       ├── wmi_check.d/conf.yaml               # SQL Server performance counters
│       ├── process.d/conf.yaml                 # SQL Server processes
│       └── sqlserver.d/
│           ├── conf.yaml                       # Standard SQL Server config
│           └── conf.yaml.alt                   # 🔐 Windows Auth alternative
│
├── sql-reporting-server/                        # SQL Reporting Services Server
│   ├── datadog.yaml                            # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/conf.yaml         # SSRS services
│       ├── win32_event_log.d/conf.yaml         # SSRS event logs
│       ├── wmi_check.d/conf.yaml               # System performance
│       ├── process.d/conf.yaml                 # SSRS processes
│       └── sqlserver.d/
│           ├── conf.yaml                       # Standard SSRS config
│           └── conf.yaml.alt                   # 🔐 Windows Auth alternative
│
├── dashboards/                                  # Datadog dashboard configurations
│   ├── sccm-overview-dashboard.json            # Main SCCM monitoring dashboard
│   ├── sccm-sql-server-health.json             # SQL Server health dashboard
│   └── sccm-sql-server-health.json.alt         # 🔐 Windows Auth dashboard alternative
│
└── widgets/                                     # Datadog widget configurations
    ├── sccm-performance-widgets.xml             # System performance widgets
    ├── sccm-service-widgets.xml                 # Service monitoring widgets
    └── sccm-sql-server-widgets.xml.alt          # 🔐 Windows Auth SQL widgets alternative
```

## Server Role Configurations

### Site Server Configuration
**Purpose**: Primary SCCM site server monitoring
**Key Components**:
- SCCM-specific services (SMS_EXECUTIVE, SMS_SITE_COMPONENT_MANAGER, SMS_NOTIFICATION_SERVER)
- IIS monitoring for SCCM web services and administration console
- Windows Event Log monitoring for SCCM and system events
- System performance metrics (CPU, memory, disk, network)
- Critical process monitoring for SCCM components
- Component status monitoring

**Monitored Services**:
- SMS_EXECUTIVE
- SMS_SITE_COMPONENT_MANAGER  
- SMS_NOTIFICATION_SERVER
- W3SVC (IIS)
- IISADMIN

### Management Point Configuration
**Purpose**: SCCM Management Point server monitoring
**Key Components**:
- Management Point services and IIS monitoring
- Client communication and certificate monitoring
- IIS performance metrics and connection tracking
- System performance monitoring
- Security event monitoring

**Monitored Services**:
- W3SVC (IIS)
- IISADMIN
- SMS_EXECUTIVE (if co-located)
- Certificate Services (if applicable)

### Distribution Point Configuration
**Purpose**: SCCM Distribution Point server monitoring
**Key Components**:
- Distribution Point services and content library monitoring
- IIS monitoring for content distribution
- WDS monitoring (if PXE-enabled)
- Storage and network utilization tracking
- Content distribution performance

**Monitored Services**:
- W3SVC (IIS)
- IISADMIN
- WDSServer (if PXE enabled)
- SMS_EXECUTIVE (if co-located)

### SQL Server Configuration

#### Standard SQL Server Configuration
**Purpose**: SCCM SQL Database server monitoring with service account authentication
**Key Components**:
- Database performance monitoring with Database Monitoring (DBM) enabled
- SCCM-specific database queries and custom metrics
- SQL Server service monitoring and health checks
- Transaction log monitoring and backup status
- Advanced performance counters and wait statistics

**Authentication**: SQL Server authentication with dedicated service account
**Configuration File**: `sql-server/conf.d/sqlserver.d/conf.yaml`

**Monitored Services**:
- MSSQLSERVER
- SQLSERVERAGENT
- SQL Server Browser (if applicable)

#### 🔐 Windows Authentication Alternative
**Purpose**: Essential SQL Server monitoring using Windows Authentication for policy-restricted environments
**Key Components**:
- Essential SQL Server performance monitoring using Windows Authentication
- Simplified SCCM database queries with basic permissions
- Core SQL Server service monitoring
- Basic performance counters accessible with Windows Authentication
- **No service account credentials required**

**Authentication**: Windows Authentication (`Trusted_Connection=yes`)
**Configuration File**: `sql-server/conf.d/sqlserver.d/conf.yaml.alt`
**Special Tags**: `auth:windows` for identification

**Key Differences from Standard**:
- Database Monitoring (DBM) disabled to reduce permission requirements
- Simplified custom queries using basic SQL permissions
- Essential performance counters only
- Uses Windows Authentication instead of SQL Server authentication

### SQL Reporting Server Configuration

#### Standard SSRS Configuration
**Purpose**: SQL Server Reporting Services monitoring with service account authentication
**Key Components**:
- SSRS service monitoring and report execution metrics
- Database connectivity monitoring for ReportServer databases
- Report performance and execution tracking
- Service health and availability monitoring

**Authentication**: SQL Server authentication with dedicated service account
**Configuration File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml`

**Monitored Services**:
- ReportServer
- SQL Server Reporting Services Web Service
- SQL Server Reporting Services Windows Service

#### 🔐 Windows Authentication Alternative
**Purpose**: Essential SSRS monitoring using Windows Authentication for policy-restricted environments
**Key Components**:
- Essential SSRS monitoring using Windows Authentication
- Basic database connectivity checks for ReportServer databases
- Core service health monitoring
- **No service account credentials required**

**Authentication**: Windows Authentication (`Trusted_Connection=yes`)
**Configuration File**: `sql-reporting-server/conf.d/sqlserver.d/conf.yaml.alt`
**Special Tags**: `auth:windows` for identification

## Deployment Methods

### Automated Deployment (Recommended)

#### Standard Deployment
```powershell
# Deploy standard configurations with SQL service accounts
.\Deploy-DatadogConfigs-Combined.ps1

# Test deployment first
.\Deploy-DatadogConfigs-Combined.ps1 -TestMode $true
```

#### Windows Authentication Deployment
```powershell
# Deploy Windows Authentication alternatives (no service accounts)
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Test Windows Auth deployment first
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true
```

### Manual Deployment
Step-by-step manual installation for environments requiring individual server configuration. See DEPLOYMENT_README.md for detailed instructions.

## Key Features

### Monitoring Capabilities
- **System Performance**: CPU, RAM, disk space, network metrics with industry-standard thresholds
- **Service Monitoring**: Critical SCCM services with automatic restart detection
- **SQL Server Health**: Database performance, SCCM-specific queries, transaction monitoring
- **Event Log Monitoring**: Critical system, application, and security events
- **Process Monitoring**: Critical SCCM and system processes
- **IIS Monitoring**: Web service performance and availability (where applicable)

### Authentication Options
- **Standard**: SQL Server authentication with service accounts
- **Windows Authentication**: Policy-compliant alternative using Windows Authentication
- **Flexible Deployment**: Single script supports both authentication methods

### Advanced Features
- **Database Monitoring (DBM)**: Advanced SQL Server monitoring (standard configuration)
- **Custom Queries**: SCCM-specific database queries for detailed insights
- **Performance Counters**: Comprehensive Windows and SQL Server performance metrics
- **Log Collection**: Centralized log collection and analysis
- **Dashboard Integration**: Pre-built dashboards and widgets

## Monitoring Thresholds

### System Performance
- **CPU Usage**: Warning at 80%, Critical at 90%
- **Memory Usage**: Warning at 85%, Critical at 95%
- **Disk Space**: Warning at 80% full, Critical at 90% full
- **Network Utilization**: Warning at 80%, Critical at 90%

### SCCM Services
- **Service Status**: Critical alert if any monitored service stops
- **Component Status**: Warning for components in warning state, Critical for failed components
- **Response Time**: Warning at 5 seconds, Critical at 10 seconds

### SQL Server (Both Standard and Windows Auth)
- **Connection Count**: Warning at 80% of max connections, Critical at 95%
- **Database Size**: Warning at 80% of allocated space, Critical at 90%
- **Transaction Log**: Warning at 70% full, Critical at 85% full
- **Buffer Cache Hit Ratio**: Warning below 90%, Critical below 85%
- **Page Life Expectancy**: Warning below 300 seconds, Critical below 180 seconds

### IIS (Management Point and Distribution Point)
- **Response Time**: Warning at 2 seconds, Critical at 5 seconds
- **Request Queue Length**: Warning at 10, Critical at 25
- **Worker Process Health**: Critical if any worker process fails

## Security Considerations

### Standard Configuration
- Dedicated service accounts with minimal required permissions
- Encrypted credential storage recommendations
- Regular credential rotation procedures
- Network segmentation for database access

### Windows Authentication Alternative
- **Benefits**: No stored credentials, uses existing Windows security infrastructure
- **Compliance**: Suitable for environments with service account policy restrictions
- **Security**: Leverages Windows Authentication and existing security policies
- **Monitoring**: Special `auth:windows` tags for identification and tracking

## Prerequisites

### Common Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Datadog Agent 7.x
- Administrator privileges on target servers
- Network connectivity to Datadog endpoints

### Standard Configuration Additional Requirements
- SQL Server 2016 or later with SQL Server authentication enabled
- Dedicated service account with appropriate SQL Server permissions
- ODBC Driver 18 for SQL Server

### Windows Authentication Additional Requirements
- SQL Server 2016 or later with Windows Authentication enabled
- Datadog Agent service account with SQL Server Windows Authentication access
- Service account with "Log on as a service" right
- ODBC Driver 18 for SQL Server

## Support and Documentation

### Primary Documentation
- **README.md**: Package overview and quick start guide
- **DEPLOYMENT_README.md**: Comprehensive deployment and installation instructions
- **PACKAGE_SUMMARY.md**: This detailed package summary

### Deployment Resources
- **Deploy-DatadogConfigs-Combined.ps1**: Unified deployment script with both authentication modes
- **servers.json**: Server role configuration template
- **LOGS/**: Deployment logs with mode-specific naming

### Alternative Configuration Resources
- **Windows Auth Configs**: `.alt` files for SQL Server and SSRS monitoring
- **Alternative Dashboards**: Windows Auth specific dashboard configurations
- **Alternative Widgets**: Windows Auth specific widget configurations

## Maintenance and Updates

### Regular Maintenance
- Monitor deployment logs for errors or warnings
- Review metrics collection to ensure data flow
- Update configurations as SCCM environment changes
- Test backup and restore procedures
- Review and update monitoring thresholds

### Security Maintenance
- **Standard Config**: Regular credential rotation and permission audits
- **Windows Auth Config**: Service account permission reviews and access audits
- **Both**: Regular security updates and monitoring infrastructure reviews

## Version Compatibility

### SCCM Versions
- SCCM Current Branch (version 1902 or later recommended)
- SCCM Technical Preview (latest branch)

### SQL Server Versions
- SQL Server 2016 (minimum)
- SQL Server 2017
- SQL Server 2019
- SQL Server 2022

### Windows Server Versions
- Windows Server 2016
- Windows Server 2019
- Windows Server 2022

### Datadog Agent Versions
- Datadog Agent 7.30 or later (recommended)
- ODBC Driver 18 for SQL Server (required for SQL monitoring)

This comprehensive monitoring package provides complete visibility into SCCM infrastructure while offering flexible authentication options to meet various organizational security policies and requirements.