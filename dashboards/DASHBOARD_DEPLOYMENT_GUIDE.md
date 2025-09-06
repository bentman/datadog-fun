# SCCM Datadog Dashboard Deployment Guide

This guide provides instructions for deploying and customizing the SCCM monitoring dashboards and widgets in your Datadog environment.

## Table of Contents

1. [Dashboard Overview](#dashboard-overview)
2. [Dashboard Deployment](#dashboard-deployment)
3. [Widget Customization](#widget-customization)
4. [Dashboard Configuration](#dashboard-configuration)
5. [Troubleshooting](#troubleshooting)

## Dashboard Overview

### Available Dashboards

#### 1. SCCM Infrastructure Overview (`sccm-infrastructure-overview.json`)
**Purpose**: Comprehensive overview of entire SCCM infrastructure
**Key Features**:
- System performance metrics (CPU, Memory, Disk) across all server roles
- Service status monitoring
- Host map visualization
- SQL Server health indicators
- Event log monitoring
- Top resource consumers

**Widgets Included**:
- 22 widgets covering all aspects of SCCM monitoring
- Template variables for filtering by role and host
- Color-coded thresholds based on industry standards
- Real-time log stream for critical events

#### 2. SCCM SQL Server Health (`sccm-sql-server-health.json`)
**Purpose**: Detailed SQL Server performance monitoring for SCCM database
**Key Features**:
- SQL Server performance counters
- SCCM-specific database metrics
- Buffer cache and memory management
- Connection and blocking monitoring
- SCCM client count and component status

**Widgets Included**:
- 13 widgets focused on SQL Server health
- SCCM database size and growth monitoring
- Query performance indicators
- Memory pressure detection

#### 3. SCCM Service Status (`sccm-service-status.json`)
**Purpose**: Comprehensive service monitoring across all SCCM server roles
**Key Features**:
- Service status by server role
- Service availability timelines
- Service event monitoring
- Detailed service status table

**Widgets Included**:
- 9 widgets dedicated to service monitoring
- Real-time service status checks
- Historical service availability trends
- Service event stream

### Widget Collections

#### 1. System Health Widgets (`sccm-system-health-widgets.xml`)
**Components**:
- CPU, Memory, and Disk usage widgets
- Service status checks
- Host map visualization
- Performance timelines
- Top resource consumer lists

#### 2. SQL Server Widgets (`sccm-sql-server-widgets.xml`)
**Components**:
- Buffer cache hit ratio monitoring
- Page life expectancy tracking
- Blocked processes detection
- Memory usage analysis
- SCCM-specific database metrics

#### 3. IIS Performance Widgets (`sccm-iis-performance-widgets.xml`)
**Components**:
- Request rate monitoring
- Connection tracking
- Response time analysis
- Queue length monitoring
- Throughput analysis

## Dashboard Deployment

### Method 1: Datadog Web Interface

1. **Access Datadog Dashboard**
   - Log into your Datadog account
   - Navigate to Dashboards → Dashboard List
   - Click "New Dashboard"

2. **Import Dashboard JSON**
   - Click the settings gear icon
   - Select "Import dashboard JSON"
   - Copy and paste the contents of the desired dashboard JSON file
   - Click "Import"

3. **Configure Template Variables**
   - Update template variable values to match your environment
   - Set default values for `role` and `host` variables
   - Save the dashboard

### Method 2: Datadog API

```bash
# Example API call to create dashboard
curl -X POST "https://api.datadoghq.com/api/v1/dashboard" \
-H "Content-Type: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
-d @sccm-infrastructure-overview.json
```

### Method 3: Terraform (Infrastructure as Code)

```hcl
resource "datadog_dashboard" "sccm_infrastructure" {
  title       = "SCCM Infrastructure Overview"
  description = "Comprehensive monitoring dashboard for SCCM infrastructure"
  layout_type = "ordered"
  
  # Import dashboard JSON content
  dashboard_lists = [datadog_dashboard_list.sccm_dashboards.id]
  
  # Template variables
  template_variable {
    name    = "role"
    prefix  = "role"
    default = "*"
  }
  
  template_variable {
    name    = "host"
    prefix  = "host"
    default = "*"
  }
  
  # Widget definitions from JSON file
  # ... (widget configurations)
}
```

## Widget Customization

### Modifying Thresholds

Update threshold values in widget configurations:

```json
"conditional_formats": [
  {
    "comparator": ">",
    "value": 85,
    "palette": "red_on_white"
  },
  {
    "comparator": ">",
    "value": 75,
    "palette": "yellow_on_white"
  }
]
```

### Adding Custom Queries

Extend dashboards with environment-specific metrics:

```json
{
  "q": "avg:custom.sccm.metric{role:sccm-*} by {host}",
  "display_type": "line",
  "style": {
    "palette": "dog_classic",
    "line_type": "solid",
    "line_width": "normal"
  }
}
```

### Widget Sizing and Layout

Adjust widget dimensions and positions:

```json
"layout": {
  "x": 0,
  "y": 4,
  "width": 6,
  "height": 3
}
```

## Dashboard Configuration

### Template Variables

Configure template variables for dynamic filtering:

#### Role Variable
```json
{
  "name": "role",
  "default": "*",
  "prefix": "role",
  "available_values": [
    "sccm-site-server",
    "sccm-management-point",
    "sccm-distribution-point",
    "sccm-sql-server",
    "sccm-sql-reporting-server"
  ]
}
```

#### Host Variable
```json
{
  "name": "host",
  "default": "*",
  "prefix": "host"
}
```

### Time Range Configuration

Set appropriate time ranges for different widget types:

- **Real-time widgets**: Last 5 minutes
- **Performance trends**: Last 4 hours
- **Capacity planning**: Last 7 days
- **Historical analysis**: Last 30 days

### Alert Integration

Configure dashboard widgets to link to related monitors:

```json
"title_size": "16",
"title_align": "left",
"title": "CPU Usage - <a href='/monitors/12345'>View Monitor</a>"
```

## Advanced Customization

### Custom Metrics Integration

Add custom SCCM metrics to dashboards:

1. **Create Custom Metrics**
   ```python
   # Example custom metric collection
   from datadog import statsd
   
   # SCCM custom metrics
   statsd.gauge('sccm.custom.deployment_success_rate', success_rate, tags=['site:primary'])
   statsd.gauge('sccm.custom.content_distribution_time', dist_time, tags=['dp:server01'])
   ```

2. **Add to Dashboard**
   ```json
   {
     "q": "avg:sccm.custom.deployment_success_rate{*} by {site}",
     "display_type": "line"
   }
   ```

### Multi-Environment Support

Configure dashboards for multiple SCCM environments:

```json
{
  "name": "environment",
  "default": "production",
  "prefix": "environment",
  "available_values": [
    "production",
    "staging",
    "development"
  ]
}
```

### Dashboard Permissions

Set appropriate access controls:

1. **Read-Only Access**: For general users
2. **Edit Access**: For SCCM administrators
3. **Admin Access**: For Datadog administrators

## Troubleshooting

### Common Issues

#### 1. Missing Metrics
**Symptoms**: Widgets show "No data" or empty graphs
**Solutions**:
- Verify Datadog Agent is running on SCCM servers
- Check integration configurations
- Validate metric names and tags
- Review agent logs for errors

#### 2. Incorrect Thresholds
**Symptoms**: Alerts triggering too frequently or not at all
**Solutions**:
- Review threshold values against environment baselines
- Adjust warning and critical levels
- Consider environment-specific variations
- Test thresholds in non-production first

#### 3. Performance Issues
**Symptoms**: Dashboards loading slowly
**Solutions**:
- Reduce time range for high-frequency queries
- Optimize query complexity
- Use appropriate aggregation functions
- Consider widget caching settings

#### 4. Template Variable Issues
**Symptoms**: Filtering not working correctly
**Solutions**:
- Verify tag consistency across metrics
- Check template variable syntax
- Ensure proper tag propagation from agents
- Validate available values list

### Validation Steps

1. **Verify Data Collection**
   ```bash
   # Check metric availability
   curl -X GET "https://api.datadoghq.com/api/v1/metrics" \
   -H "DD-API-KEY: ${DD_API_KEY}" \
   -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | grep sccm
   ```

2. **Test Widget Queries**
   - Use Datadog Metrics Explorer
   - Validate query syntax
   - Check data availability and time ranges
   - Verify tag filtering

3. **Monitor Dashboard Performance**
   - Check dashboard load times
   - Monitor query execution times
   - Review resource usage
   - Optimize slow-performing widgets

### Support Resources

- **Datadog Documentation**: https://docs.datadoghq.com/dashboards/
- **API Reference**: https://docs.datadoghq.com/api/latest/dashboards/
- **Community Forums**: https://community.datadoghq.com/
- **SCCM Monitoring Best Practices**: Refer to Microsoft documentation

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review dashboard performance
   - Check for new metrics availability
   - Validate threshold effectiveness

2. **Monthly**
   - Update thresholds based on trends
   - Add new widgets for emerging requirements
   - Review and optimize slow queries

3. **Quarterly**
   - Comprehensive dashboard review
   - Update documentation
   - Train new users on dashboard usage

### Version Control

Maintain dashboard configurations in version control:

```bash
# Example Git workflow
git add dashboards/
git commit -m "Update SCCM dashboard thresholds"
git push origin main
```

---

This deployment guide ensures successful implementation and ongoing maintenance of your SCCM monitoring dashboards in Datadog.