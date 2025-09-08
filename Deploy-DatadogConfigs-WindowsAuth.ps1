<#
.SYNOPSIS
    Deploys SCCM Datadog monitoring configurations with Windows Authentication alternative to target servers.

.DESCRIPTION
    This script distributes role-specific Datadog Agent configurations to SCCM servers with support
    for Windows Authentication alternatives. It handles both standard and alternative configurations
    for environments where service accounts cannot be used.
    
    The script copies configuration files from the local repository structure to the
    appropriate Datadog Agent directories on target servers, backing up existing
    configurations before deployment.

.PARAMETER ConfigPath
    Path to the local configuration repository. Defaults to script directory.

.PARAMETER ServerConfig
    Path to JSON file containing server role mappings. Defaults to 'servers.json' in script directory.

.PARAMETER UseWindowsAuth
    Deploy Windows Authentication alternative configurations instead of standard configs. Default: $false

.PARAMETER BackupConfigs
    Creates backup of existing configurations before deployment. Default: $true

.PARAMETER TestMode
    Performs validation without actual file deployment. Default: $false

.EXAMPLE
    .\Deploy-DatadogConfigs-WindowsAuth.ps1 -UseWindowsAuth $true
    Deploys Windows Authentication alternative configurations.

.EXAMPLE
    .\Deploy-DatadogConfigs-WindowsAuth.ps1 -ConfigPath "C:\SCCM-Configs" -TestMode $true
    Validates deployment without copying files.

.EXAMPLE
    .\Deploy-DatadogConfigs-WindowsAuth.ps1 -UseWindowsAuth $true -ServerConfig "production-servers.json"
    Deploys Windows Auth configs using custom server list.

.NOTES
    Author: SCCM Datadog Deployment Script (Windows Auth Alternative)
    Version: 1.1
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
    [bool]$UseWindowsAuth = $false,
    
    [Parameter(Mandatory=$false)]
    [bool]$BackupConfigs = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$TestMode = $false
)

# Configuration mappings
$RoleConfigurations = @{
    "site-server" = @{
        "ConfigDir" = "site-server"
        "TargetPath" = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "management-point" = @{
        "ConfigDir" = "management-point"
        "TargetPath" = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "distribution-point" = @{
        "ConfigDir" = "distribution-point"
        "TargetPath" = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "sql-server" = @{
        "ConfigDir" = "sql-server"
        "TargetPath" = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
        "HasWindowsAuthAlt" = $true
    }
    "sql-reporting-server" = @{
        "ConfigDir" = "sql-reporting-server"
        "TargetPath" = "C:\ProgramData\Datadog"
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
    
    # Also write to log file
    $logFile = Join-Path $PSScriptRoot "deployment-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logMessage
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
            $existingConfigs = Get-ChildItem -Path $remotePath -Include "*.yaml", "conf.d" -Recurse
            foreach ($config in $existingConfigs) {
                $relativePath = $config.FullName.Replace($remotePath, "")
                $backupTarget = Join-Path $backupPath $relativePath
                $backupTargetDir = Split-Path $backupTarget -Parent
                
                if (-not (Test-Path $backupTargetDir)) {
                    New-Item -Path $backupTargetDir -ItemType Directory -Force | Out-Null
                }
                
                Copy-Item -Path $config.FullName -Destination $backupTarget -Force
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
    }
    
    return $sourcePath
}

function Restart-DatadogAgent {
    param(
        [string]$TargetServer
    )
    
    if ($TestMode) {
        Write-Log "TEST MODE: Would restart Datadog Agent on $TargetServer" "INFO"
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

function Deploy-DashboardsAndWidgets {
    if ($UseWindowsAuth) {
        Write-Log "Windows Authentication mode - Dashboard and widget alternatives available"
        Write-Log "Alternative dashboard: dashboards/sccm-sql-server-health.json.alt"
        Write-Log "Alternative widgets: widgets/sccm-sql-server-widgets.xml.alt"
        Write-Log "Please manually import these alternatives to your Datadog account"
        Write-Log "See WINDOWS_AUTH_ALTERNATIVE_README.md for detailed instructions"
    }
}

# Main execution
function Main {
    Write-Log "Starting SCCM Datadog Configuration Deployment"
    Write-Log "Configuration Path: $ConfigPath"
    Write-Log "Server Config: $ServerConfig"
    Write-Log "Windows Authentication Mode: $UseWindowsAuth"
    Write-Log "Test Mode: $TestMode"
    
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
        
        Write-Log "Processing role: $role ($($serverList.Count) servers)"
        
        foreach ($server in $serverList) {
            $totalServers++
            Write-Log "Deploying to $server (Role: $role)"
            
            $sourcePath = Get-ConfigurationSource -Role $role -ConfigDir $roleConfig.ConfigDir
            
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
            }
            
            # Clean up temporary directories for Windows Auth
            if ($UseWindowsAuth -and $sourcePath.StartsWith($env:TEMP)) {
                Remove-Item -Path $sourcePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Deploy dashboards and widgets information
    Deploy-DashboardsAndWidgets
    
    # Summary
    Write-Log "Deployment Summary:"
    Write-Log "Total Servers: $totalServers"
    Write-Log "Successful Deployments: $successfulDeployments"
    Write-Log "Failed Deployments: $($totalServers - $successfulDeployments)"
    
    if ($UseWindowsAuth) {
        Write-Log ""
        Write-Log "Windows Authentication Alternative Deployment Complete"
        Write-Log "Please review WINDOWS_AUTH_ALTERNATIVE_README.md for:"
        Write-Log "- Configuration validation steps"
        Write-Log "- Dashboard and widget import instructions"
        Write-Log "- Troubleshooting guidance"
    }
    
    # Detailed results
    Write-Log "Detailed Results:"
    foreach ($server in $deploymentResults.Keys) {
        $result = $deploymentResults[$server]
        $status = if ($result.Success) { "SUCCESS" } else { "FAILED" }
        Write-Log "$server ($($result.Role)): $status"
    }
    
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