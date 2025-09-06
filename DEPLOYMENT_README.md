# Datadog Configuration Deployment

This directory contains a PowerShell script for deploying SCCM Datadog monitoring configurations to target servers.

## Files

- `Deploy-DatadogConfigs.ps1` - Main deployment script
- `servers.json` - Server role configuration (template)
- `DEPLOYMENT_README.md` - This file

## Quick Start

1. **Configure Target Servers**
   ```powershell
   # Edit servers.json with your actual server names
   notepad servers.json
   ```

2. **Test Deployment** (recommended first run)
   ```powershell
   .\Deploy-DatadogConfigs.ps1 -TestMode $true
   ```

3. **Deploy Configurations**
   ```powershell
   .\Deploy-DatadogConfigs.ps1
   ```

## Prerequisites

- PowerShell 5.1 or later
- Administrative access to target servers
- PowerShell Remoting enabled on target servers
- Network connectivity to all target servers

## Server Configuration Format

Edit `servers.json` to match your environment:

```json
{
    "site-server": ["your-site-server.domain.com"],
    "management-point": ["mp1.domain.com", "mp2.domain.com"],
    "distribution-point": ["dp1.domain.com", "dp2.domain.com"],
    "sql-server": ["sql.domain.com"],
    "sql-reporting-server": ["ssrs.domain.com"]
}
```

## Script Features

- **Multi-server support** - Deploy to multiple servers per role
- **Automatic backups** - Creates timestamped backups of existing configurations
- **Test mode** - Validate deployment without making changes
- **Error handling** - Continues deployment even if individual servers fail
- **Logging** - Creates detailed logs in `LOGS\` directory
- **Results tracking** - Saves deployment results to JSON file

## Common Usage Examples

```powershell
# Test deployment without making changes
.\Deploy-DatadogConfigs.ps1 -TestMode $true

# Deploy without creating backups
.\Deploy-DatadogConfigs.ps1 -BackupConfigs $false

# Use custom server configuration file
.\Deploy-DatadogConfigs.ps1 -ServerConfig "production-servers.json"

# Deploy from different configuration path
.\Deploy-DatadogConfigs.ps1 -ConfigPath "C:\SCCM-Datadog-Configs"
```

## Troubleshooting

- **Connection Issues**: Ensure PowerShell Remoting is enabled on target servers
- **Permission Errors**: Run as administrator with appropriate domain privileges
- **File Access**: Verify Datadog Agent service is stopped during deployment if file locks occur
- **Logs**: Check `LOGS\` directory for detailed execution logs

## Post-Deployment

After successful deployment:

1. Restart Datadog Agent service on each server
2. Verify agent status: `& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status`
3. Check Datadog dashboard for incoming metrics
4. Review agent logs for any configuration errors