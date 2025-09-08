<#
.SYNOPSIS
    Deploys SCCM Datadog monitoring configurations to target servers with support for both standard and Windows Authentication alternatives.

.DESCRIPTION
    This script distributes role-specific Datadog Agent configurations to SCCM servers with unified functionality
    for both standard and Windows Authentication deployments. It handles file deployment, service restarts,
    backup creation, and comprehensive logging.
    
    The script copies configuration files from the local repository structure to the
    appropriate Datadog Agent directories on target servers, backing up existing
    configurations before deployment.

.PARAMETER ConfigPath
    Path to the local configuration repository. Defaults to script directory.

.PARAMETER ServerConfig
    Path to JSON file containing server role mappings. Defaults to 'servers.json' in script directory.

.PARAMETER UseWindowsAuth
    Deploy Windows Authentication alternative configurations (.alt files) instead of standard configs. Default: $false

.PARAMETER BackupConfigs
    Creates backup of existing configurations before deployment. Default: $true

.PARAMETER RestartService
    Restart Datadog Agent service after deployment. Default: $true

.PARAMETER TestMode
    Performs validation without actual file deployment or service restart. Default: $false

.EXAMPLE
    .\Deploy-DatadogConfigs-Combined.ps1
    Deploys standard configurations using default settings and servers.json file.

.EXAMPLE
    .\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth
    Deploys Windows Authentication alternative configurations.

.EXAMPLE
    .\Deploy-DatadogConfigs-Combined.ps1 -ConfigPath "C:\SCCM-Configs" -TestMode
    Validates deployment without copying files or restarting services.

.EXAMPLE
    .\Deploy-DatadogConfigs-Combined.ps1 -UseWindowsAuth -ServerConfig "production-servers.json" -BackupConfigs $false
    Deploys Windows Auth configs using custom server list without creating backups.

.NOTES
    Author: SCCM Datadog Deployment Script (Combined)
    Version: 2.0
    Requires: PowerShell 5.1+, Administrative privileges on target servers
    
    Server JSON Format:
    {
        "site-server": ["server1.domain.com", "server2.domain.com"],
        "management-point": ["mp1.domain.com", "mp2.domain.com"],
        "distribution-point": ["dp1.domain.com", "dp2.domain.com"],
        "sql-server": ["sql1.domain.com"],
        "sql-reporting-server": ["ssrs1.domain.com"]
    }
    
    Windows Authentication Requirements:
    - SQL Server must have Windows Authentication enabled
    - Datadog Agent service account must have SQL Server access
    - Agent service account must have log file read permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = $PSScriptRoot,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerConfig = (Join-Path $PSScriptRoot "servers.json"),
    
    [Parameter(Mandatory=$false)]
    [switch]$UseWindowsAuth = $false,
    
    [Parameter(Mandatory=$false)]
    [bool]$BackupConfigs = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$RestartService = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$TestMode = $false
)

# Ensure LOGS directory exists
$LogsDir = Join-Path $PSScriptRoot "LOGS"
if (-not (Test-Path $LogsDir)) {
    New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
}

# Set log file based on deployment mode
if ($UseWindowsAuth) {
    $LogFile = Join-Path $LogsDir "Datadog_DeployConfigsAltAuth-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
} else {
    $LogFile = Join-Path $LogsDir "Datadog_DeployConfigs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
}

# Configuration mappings
$RoleConfigurations = @{
    "site-server" = @{
        "ConfigDir" = "site-server"
        "TargetPath" = "C:\ProgramData\Datadog"
        "Description" = "SCCM Primary Site Server"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $false
    }
    "management-point" = @{
        "ConfigDir" = "management-point"
        "TargetPath" = "C:\ProgramData\Datadog"
        "Description" = "SCCM Management Point"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $false
    }
    "distribution-point" = @{
        "ConfigDir" = "distribution-point"
        "TargetPath" = "C:\ProgramData\Datadog"
        "Description" = "SCCM Distribution Point"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $false
    }
    "sql-server" = @{
        "ConfigDir" = "sql-server"
        "TargetPath" = "C:\ProgramData\Datadog"
        "Description" = "SCCM SQL Database Server"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $true
    }
    "sql-reporting-server" = @{
        "ConfigDir" = "sql-reporting-server"
        "TargetPath" = "C:\ProgramData\Datadog"
        "Description" = "SQL Reporting Services Server"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $true
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logMessage
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    # Check if running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Script must be run as Administrator" "ERROR"
        return $false
    }
    
    # Check if configuration path exists
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "Configuration path not found: $ConfigPath" "ERROR"
        return $false
    }
    
    # Check if server configuration file exists
    if (-not (Test-Path $ServerConfig)) {
        Write-Log "Server configuration file not found: $ServerConfig" "ERROR"
        return $false
    }
    
    Write-Log "Prerequisites check passed"
    return $true
}

function Get-ServerConfiguration {
    try {
        $servers = Get-Content $ServerConfig | ConvertFrom-Json
        Write-Log "Loaded server configuration from $ServerConfig"
        return $servers
    }
    catch {
        Write-Log "Failed to load server configuration: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-ConfigurationSource {
    param(
        [string]$Role,
        [string]$ConfigDir
    )
    
    $sourcePath = Join-Path $ConfigPath $ConfigDir
    
    if ($UseWindowsAuth -and $RoleConfigurations[$Role].HasWindowsAuthAlt) {
        Write-Log "Using Windows Authentication alternative configuration for $Role"
        
        # For SQL roles, we need to handle the alternative files
        if ($Role -eq "sql-server" -or $Role -eq "sql-reporting-server") {
            # Create a temporary directory with the alternative configuration
            $tempPath = Join-Path $env:TEMP "datadog-winauth-$Role-$(Get-Date -Format 'yyyyMMddHHmmss')"
            New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
            
            # Copy all files from source
            Copy-Item -Path "$sourcePath\*" -Destination $tempPath -Recurse -Force
            
            # Replace the main SQL Server config with the alternative
            $altConfigPath = Join-Path $sourcePath "conf.d\sqlserver.d\conf.yaml.alt"
            $targetConfigPath = Join-Path $tempPath "conf.d\sqlserver.d\conf.yaml"
            
            if (Test-Path $altConfigPath) {
                Copy-Item -Path $altConfigPath -Destination $targetConfigPath -Force
                Write-Log "Replaced SQL Server config with Windows Auth alternative"
            } else {
                Write-Log "Windows Auth alternative not found: $altConfigPath" "WARNING"
            }
            
            return $tempPath
        }
    } elseif ($UseWindowsAuth -and -not $RoleConfigurations[$Role].HasWindowsAuthAlt) {
        Write-Log "Windows Authentication requested but no alternative available for role: $Role" "WARNING"
    }
    
    return $sourcePath
}

function Deploy-ConfigurationFiles {
    param(
        [string]$SourcePath,
        [string]$TargetServer,
        [string]$TargetPath,
        [bool]$CreateBackup = $true
    )
    
    Write-Log "Deploying configuration from $SourcePath to $TargetServer"
    
    if ($TestMode) {
        Write-Log "TEST MODE: Would deploy to \\$TargetServer\$($TargetPath.Replace(':', '$'))" "INFO"
        return $true
    }
    
    try {
        $remotePath = "\\$TargetServer\$($TargetPath.Replace(':', '$'))"
        
        # Test connectivity
        if (-not (Test-Path $remotePath)) {
            Write-Log "Cannot access remote path: $remotePath" "ERROR"
            return $false
        }
        
        # Create backup if requested
        if ($CreateBackup) {
            $backupPath = Join-Path $remotePath "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            if (-not (Test-Path $backupPath)) {
                New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
            }
            
            # Backup existing configurations
            $existingConfigs = Get-ChildItem -Path $remotePath -Include "*.yaml", "conf.d" -Recurse -ErrorAction SilentlyContinue
            foreach ($config in $existingConfigs) {
                try {
                    $relativePath = $config.FullName.Replace($remotePath, "").TrimStart('\')
                    $backupTarget = Join-Path $backupPath $relativePath
                    $backupTargetDir = Split-Path $backupTarget -Parent
                    
                    if (-not (Test-Path $backupTargetDir)) {
                        New-Item -Path $backupTargetDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Copy-Item -Path $config.FullName -Destination $backupTarget -Force
                } catch {
                    Write-Log "Warning: Could not backup $($config.FullName): $($_.Exception.Message)" "WARNING"
                }
            }
            Write-Log "Created backup at $backupPath"
        }
        
        # Copy new configurations
        Copy-Item -Path "$SourcePath\*" -Destination $remotePath -Recurse -Force
        Write-Log "Successfully deployed configuration to $TargetServer"
        return $true
    }
    catch {
        Write-Log "Failed to deploy configuration to $TargetServer`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restart-DatadogAgent {
    param(
        [string]$TargetServer
    )
    
    if ($TestMode) {
        Write-Log "TEST MODE: Would restart Datadog Agent on $TargetServer" "INFO"
        return $true
    }
    
    if (-not $RestartService) {
        Write-Log "Service restart disabled, skipping restart on $TargetServer" "INFO"
        return $true
    }
    
    try {
        Write-Log "Restarting Datadog Agent on $TargetServer"
        Invoke-Command -ComputerName $TargetServer -ScriptBlock {
            Restart-Service -Name "DatadogAgent" -Force
        } -ErrorAction Stop
        
        Write-Log "Successfully restarted Datadog Agent on $TargetServer"
        return $true
    }
    catch {
        Write-Log "Failed to restart Datadog Agent on $TargetServer`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-PostDeploymentInfo {
    if ($UseWindowsAuth) {
        Write-Log ""
        Write-Log "Windows Authentication Alternative Deployment Complete"
        Write-Log "Additional Resources Available:"
        Write-Log "- Alternative dashboard: dashboards/sccm-sql-server-health.json.alt"
        Write-Log "- Alternative widgets: widgets/sccm-sql-server-widgets.xml.alt"
        Write-Log "- Comprehensive guide: WINDOWS_AUTH_ALTERNATIVE_README.md"
        Write-Log "- File inventory: WINDOWS_AUTH_FILES_SUMMARY.md"
        Write-Log ""
        Write-Log "Next Steps:"
        Write-Log "1. Verify metrics collection with 'auth:windows' tag"
        Write-Log "2. Import alternative dashboard and widgets to Datadog"
        Write-Log "3. Check Agent logs for authentication issues"
        Write-Log "4. Review troubleshooting guide if needed"
    } else {
        Write-Log ""
        Write-Log "Standard Configuration Deployment Complete"
        Write-Log "Next Steps:"
        Write-Log "1. Verify SQL Server authentication credentials"
        Write-Log "2. Check metrics collection in Datadog"
        Write-Log "3. Review Agent logs for any connection issues"
        Write-Log "4. Import dashboards and configure alerts as needed"
    }
}

# Main execution
function Main {
    $deploymentMode = if ($UseWindowsAuth) { "Windows Authentication Alternative" } else { "Standard" }
    
    Write-Log "Starting SCCM Datadog Configuration Deployment ($deploymentMode Mode)"
    Write-Log "Configuration Path: $ConfigPath"
    Write-Log "Server Config: $ServerConfig"
    Write-Log "Windows Authentication Mode: $UseWindowsAuth"
    Write-Log "Backup Configs: $BackupConfigs"
    Write-Log "Restart Service: $RestartService"
    Write-Log "Test Mode: $TestMode"
    Write-Log "Log File: $LogFile"
    
    if (-not (Test-Prerequisites)) {
        Write-Log "Prerequisites check failed. Exiting." "ERROR"
        exit 1
    }
    
    $servers = Get-ServerConfiguration
    if (-not $servers) {
        Write-Log "Failed to load server configuration. Exiting." "ERROR"
        exit 1
    }
    
    $deploymentResults = @{}
    $totalServers = 0
    $successfulDeployments = 0
    $tempDirectories = @()
    
    foreach ($role in $servers.PSObject.Properties.Name) {
        if (-not $RoleConfigurations.ContainsKey($role)) {
            Write-Log "Unknown role: $role" "WARNING"
            continue
        }
        
        $roleConfig = $RoleConfigurations[$role]
        $serverList = $servers.$role
        
        if (-not $serverList -or $serverList.Count -eq 0) {
            Write-Log "No servers defined for role: $role" "WARNING"
            continue
        }
        
        Write-Log "Processing role: $role - $($roleConfig.Description) ($($serverList.Count) servers)"
        
        foreach ($server in $serverList) {
            $totalServers++
            Write-Log "Deploying to $server (Role: $role)"
            
            $sourcePath = Get-ConfigurationSource -Role $role -ConfigDir $roleConfig.ConfigDir
            
            # Track temp directories for cleanup
            if ($sourcePath.StartsWith($env:TEMP)) {
                $tempDirectories += $sourcePath
            }
            
            $deploySuccess = Deploy-ConfigurationFiles -SourcePath $sourcePath -TargetServer $server -TargetPath $roleConfig.TargetPath -CreateBackup $BackupConfigs
            
            if ($deploySuccess -and $roleConfig.RequiresRestart) {
                $restartSuccess = Restart-DatadogAgent -TargetServer $server
                $deploySuccess = $deploySuccess -and $restartSuccess
            }
            
            if ($deploySuccess) {
                $successfulDeployments++
                Write-Log "Successfully deployed to $server" "SUCCESS"
            } else {
                Write-Log "Failed to deploy to $server" "ERROR"
            }
            
            $deploymentResults[$server] = @{
                "Role" = $role
                "Success" = $deploySuccess
                "Description" = $roleConfig.Description
            }
        }
    }
    
    # Clean up temporary directories
    foreach ($tempDir in $tempDirectories) {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Cleaned up temporary directory: $tempDir"
        }
    }
    
    # Show post-deployment information
    Show-PostDeploymentInfo
    
    # Summary
    Write-Log ""
    Write-Log "=== DEPLOYMENT SUMMARY ==="
    Write-Log "Deployment Mode: $deploymentMode"
    Write-Log "Total Servers: $totalServers"
    Write-Log "Successful Deployments: $successfulDeployments"
    Write-Log "Failed Deployments: $($totalServers - $successfulDeployments)"
    
    # Detailed results
    Write-Log ""
    Write-Log "=== DETAILED RESULTS ==="
    foreach ($server in $deploymentResults.Keys | Sort-Object) {
        $result = $deploymentResults[$server]
        $status = if ($result.Success) { "SUCCESS" } else { "FAILED" }
        Write-Log "$server [$($result.Role)] - $($result.Description): $status"
    }
    
    Write-Log ""
    Write-Log "Deployment log saved to: $LogFile"
    
    if ($successfulDeployments -eq $totalServers) {
        Write-Log "All deployments completed successfully!" "SUCCESS"
        exit 0
    } else {
        Write-Log "Some deployments failed. Check logs for details." "WARNING"
        exit 1
    }
}

# Execute main function
Main