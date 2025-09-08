# Datadog Configuration Deployment Scripts Guide

This document explains the available PowerShell deployment scripts for SCCM Datadog monitoring configurations.

## Available Scripts

### 1. Deploy-DatadogConfigs-Combined.ps1 (Recommended)
**Status**: ✅ **Current - Unified Solution**

The combined deployment script that merges functionality from both original scripts with consistent behavior and enhanced features.

#### Key Features:
- **Unified functionality** for both standard and Windows Authentication deployments
- **Consistent service restart** behavior for both modes
- **Enhanced logging** with mode-specific log files
- **Comprehensive error handling** and validation
- **Test mode** for validation without deployment
- **Automatic backup** creation before deployment
- **Temporary directory cleanup** for Windows Auth mode

#### Usage Examples:
```powershell
# Deploy standard configurations
.\Deploy-DatadogConfigs-Combined.ps1

# Deploy Windows Authentication alternatives
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth

# Test deployment without making changes
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true

# Deploy without service restart
.\Deploy-DatadogConfigs-Combined.ps1 -RestartService $false

# Deploy without creating backups
.\Deploy-DatadogConfigs-Combined.ps1 -BackupConfigs $false
```

#### Log Files:
- Standard mode: `LOGS\Datadog_DeployConfigs-yyyyMMdd-HHmmss.log`
- Windows Auth mode: `LOGS\Datadog_DeployConfigsAltAuth-yyyyMMdd-HHmmss.log`

### 2. Deploy-DatadogConfigs.ps1 (Legacy)
**Status**: ⚠️ **Legacy - Limited Functionality**

The original deployment script with basic functionality.

#### Limitations:
- **No service restart** functionality
- **Basic error handling**
- **Limited logging**
- **No Windows Authentication support**

#### When to Use:
- Legacy environments where service restart is handled separately
- Minimal deployment scenarios
- Backward compatibility requirements

### 3. Deploy-DatadogConfigs-WindowsAuth.ps1 (Specialized)
**Status**: ⚠️ **Specialized - Windows Auth Only**

The Windows Authentication specific deployment script.

#### Limitations:
- **Windows Auth only** - cannot deploy standard configurations
- **Separate maintenance** required
- **Duplicated functionality** with combined script

#### When to Use:
- Environments that exclusively use Windows Authentication
- When combined script is not available
- Specialized Windows Auth deployments

## Migration Recommendations

### From Legacy Scripts to Combined Script

#### Current State Analysis:
| Feature | Original Script | Windows Auth Script | Combined Script |
|---------|----------------|-------------------|-----------------|
| Service Restart | ❌ No | ✅ Yes | ✅ Yes |
| Windows Auth Support | ❌ No | ✅ Yes | ✅ Yes |
| Standard Config Support | ✅ Yes | ❌ No | ✅ Yes |
| Enhanced Logging | ❌ Basic | ✅ Yes | ✅ Yes |
| Test Mode | ❌ No | ❌ No | ✅ Yes |
| Backup Creation | ✅ Yes | ✅ Yes | ✅ Yes |
| Error Handling | ❌ Basic | ✅ Good | ✅ Enhanced |

#### Migration Steps:
1. **Test the combined script** in your environment using `-TestMode $true`
2. **Update deployment procedures** to use the combined script
3. **Update documentation** and runbooks
4. **Train team members** on the new unified approach
5. **Archive legacy scripts** once migration is complete

## Script Parameters Comparison

### Combined Script Parameters:
```powershell
[Parameter] $ConfigPath = $PSScriptRoot           # Configuration source path
[Parameter] $ServerConfig = "servers.json"       # Server configuration file
[Switch]    $UseWindowsAuth = $false             # Deploy Windows Auth alternatives
[Bool]      $BackupConfigs = $true               # Create configuration backups
[Bool]      $RestartService = $true              # Restart Datadog Agent service
[Bool]      $TestMode = $false                   # Test mode (no actual deployment)
```

### Legacy Script Parameters:
```powershell
[Parameter] $ConfigPath = $PSScriptRoot          # Configuration source path
[Parameter] $ServerConfig = "servers.json"      # Server configuration file
# Note: No service restart, Windows Auth, or test mode support
```

### Windows Auth Script Parameters:
```powershell
[Parameter] $ConfigPath = $PSScriptRoot          # Configuration source path
[Parameter] $ServerConfig = "servers.json"      # Server configuration file
[Bool]      $UseWindowsAuth = $false            # Windows Auth mode (required)
# Note: Always restarts service, no test mode
```

## Best Practices

### 1. Use the Combined Script
- **Recommended approach** for all new deployments
- **Consistent behavior** across deployment modes
- **Enhanced features** and error handling

### 2. Test Before Deployment
```powershell
# Always test first
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -TestMode $true

# Then deploy
.\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth
```

### 3. Monitor Deployment Logs
- Check the generated log files in the `LOGS` directory
- Review deployment results and error messages
- Verify service restart success

### 4. Backup Strategy
- Keep backups enabled (`-BackupConfigs $true`) by default
- Test restore procedures periodically
- Document backup locations for recovery

## Troubleshooting

### Common Issues and Solutions:

#### 1. Service Restart Failures
```powershell
# Deploy without restart, then restart manually
.\Deploy-DatadogConfigs-Combined.ps1 -RestartService $false
Invoke-Command -ComputerName "target-server" -ScriptBlock { Restart-Service DatadogAgent }
```

#### 2. Permission Issues
```powershell
# Run as Administrator
# Verify WinRM is enabled on target servers
# Check firewall settings
```

#### 3. Windows Authentication Issues
```powershell
# Verify service account permissions
# Check SQL Server Windows Authentication settings
# Review Datadog Agent service account configuration
```

## Future Considerations

### Script Consolidation Benefits:
- **Reduced maintenance overhead** - single script to maintain
- **Consistent functionality** - same features across deployment modes
- **Improved testing** - unified test procedures
- **Better documentation** - single source of truth

### Deprecation Timeline:
1. **Phase 1**: Introduce combined script alongside existing scripts
2. **Phase 2**: Update documentation to recommend combined script
3. **Phase 3**: Migrate existing deployments to combined script
4. **Phase 4**: Deprecate legacy scripts (with notice period)
5. **Phase 5**: Remove legacy scripts from repository

## Support and Maintenance

### Primary Script: Deploy-DatadogConfigs-Combined.ps1
- **Active development** and feature additions
- **Bug fixes** and security updates
- **Enhanced functionality** based on user feedback

### Legacy Scripts: Maintenance Mode
- **Critical bug fixes** only
- **No new features**
- **Deprecation notices** in future versions

For questions or issues with deployment scripts, refer to the comprehensive logging output and troubleshooting sections in the respective documentation files.