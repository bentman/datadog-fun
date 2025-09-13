# SCCM Datadog Monitoring - Project Components

This document provides a structural overview of the project components and their specific monitoring configurations. Each component is designed for specific SCCM server roles with tailored monitoring focused on role-specific services and performance metrics.

## Project Structure

```
datadog-fun/
├── site-server/                    # Primary Site Server configuration
│   ├── datadog.yaml               # Main agent configuration
│   └── conf.d/
│       ├── windows_service.d/     # SCCM service monitoring
│       ├── win32_event_log.d/     # Windows event log monitoring
│       ├── wmi_check.d/          # WMI performance counters
│       ├── process.d/            # Process monitoring
│       └── iis.d/                # IIS web server monitoring
├── management-point/               # Management Point configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── iis.d/
├── distribution-point/             # Distribution Point configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── iis.d/
├── sql-server/                     # SQL Database Server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── sqlserver.d/          # SQL Server monitoring
├── sql-reporting-server/           # SQL Reporting Server configuration
│   ├── datadog.yaml
│   └── conf.d/
│       ├── windows_service.d/
│       ├── win32_event_log.d/
│       ├── wmi_check.d/
│       ├── process.d/
│       └── sqlserver.d/
├── dashboards/                     # Datadog dashboard templates
│   ├── sccm-sql-applications.json
│   └── windows-server-health.json
├── common/                         # Shared configuration files
│   ├── recommended-thresholds.yaml
│   └── system-probe.yaml
├── servers.json                    # Server inventory configuration
└── Deploy-DatadogConfigs.ps1      # Automated deployment script
```

## Component Descriptions

### Site Server
The primary SCCM site server handles overall site management and coordination. Monitoring provides essential service health, system performance, and event logging with LCD approach for reliable operation.

### Management Point
Serves as the primary client communication endpoint in SCCM infrastructure. Monitoring provides essential service health, IIS performance for client communications, and system metrics for reliable operation.

### Distribution Point
Handles content distribution to SCCM clients across the network. Monitoring provides essential service health, system performance with emphasis on disk and network utilization, and IIS monitoring for content distribution reliability.

### SQL Server
Hosts the SCCM database and provides core data services. Monitoring focuses on SQL Server performance metrics, database health, and system resources using Windows Authentication for security-compliant operation.

### SQL Reporting Server
Provides SCCM reporting services through SQL Server Reporting Services. Monitoring emphasizes SSRS performance, report execution, and database connectivity using Windows Authentication for secure reporting delivery.

## Configuration Components

### datadog.yaml
Main Datadog Agent configuration file containing API key, logging settings, and agent-specific parameters. Each role has customized settings for optimal performance and security including Windows Authentication configurations for SQL Server roles.

### windows_service.d
Monitors critical Windows services specific to each SCCM role. Configurations include service status checks, startup type validation, and service dependency monitoring with role-appropriate service lists and alerting thresholds.

### win32_event_log.d
Comprehensive Windows Event Log monitoring with pattern-based filtering for critical events. Includes system events, security events, application events, and role-specific operational events with optimized regex patterns for performance.

### wmi_check.d
Windows Management Instrumentation monitoring for system performance metrics. Covers CPU usage, memory utilization, disk space, network performance, and role-specific performance counters with industry-standard thresholds.

### process.d
Process-level monitoring for critical SCCM processes and applications. Includes process existence checks, resource utilization monitoring, and process performance metrics with role-specific process lists and alerting configurations.

### iis.d
Internet Information Services monitoring for web-enabled SCCM roles. Covers IIS performance metrics, application pool health, request processing, and HTTP error monitoring with comprehensive IIS-specific alerting and performance tracking.

### sqlserver.d
SQL Server monitoring for database-enabled SCCM roles using Windows Authentication. Includes database performance metrics, connection monitoring, backup status, and SCCM-specific database queries with secure authentication and comprehensive performance tracking.

## Dashboard Components

### sccm-sql-applications.json
Pre-built Datadog dashboard template for SCCM SQL Server monitoring. Includes database performance widgets, connection metrics, backup status, and SCCM-specific database health indicators with customizable time ranges and filtering options.

### windows-server-health.json
Comprehensive Windows Server health dashboard template. Features system performance metrics, service status, event log summaries, and infrastructure health indicators with role-based filtering and alerting integration.

## Common Components

### recommended-thresholds.yaml
Industry-standard monitoring thresholds for all metrics and services. Includes CPU, memory, disk, network, and service-specific thresholds with warning and critical levels based on best practices and field experience.

### system-probe.yaml
System-level probe configuration for network and process monitoring. Provides enhanced visibility into system-level operations, network connections, and process relationships with security-focused monitoring capabilities.

## Deployment Components

### servers.json
Server inventory configuration file defining SCCM infrastructure layout. Contains server hostnames, roles, descriptions, and deployment-specific parameters with support for complex multi-server environments and role-based deployments.

### Deploy-DatadogConfigs.ps1
Automated PowerShell deployment script for consistent configuration deployment. Features role detection, configuration backup, service management, and comprehensive logging with support for test mode and customizable deployment options.
