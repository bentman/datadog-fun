<#
.SYNOPSIS
    Deploys SCCM Datadog monitoring configurations to target servers.

.DESCRIPTION
    This script distributes role-specific Datadog Agent configurations to SCCM servers.
    Supports multiple servers per role and handles file deployment with basic error handling.
    
    The script copies configuration files from the local repository structure to the
    appropriate Datadog Agent directories on target servers, backing up existing
    configurations before deployment.

.PARAMETER ConfigPath
    Path to the local configuration repository. Defaults to script directory.

.PARAMETER ServerConfig
    Path to JSON file containing server role mappings. Defaults to 'servers.json' in script directory.

.PARAMETER BackupConfigs
    Creates backup of existing configurations before deployment. Default: $true

.PARAMETER TestMode
    Performs validation without actual file deployment. Default: $false

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1
    Deploys configurations using default settings and servers.json file.

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1 -ConfigPath "C:\SCCM-Configs" -TestMode $true
    Validates deployment without copying files.

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1 -ServerConfig "production-servers.json" -BackupConfigs $false
    Deploys using custom server list without creating backups.

.NOTES
    Author: SCCM Datadog Deployment Script
    Version: 1.0
    Requires: PowerShell 5.1+, Administrative privileges on target servers
    
    Server JSON Format:
    {
        "site-server": ["server1.domain.com", "server2.domain.com"],
        "management-point": ["mp1.domain.com", "mp2.domain.com"],
        "distribution-point": ["dp1.domain.com", "dp2.domain.com"],
        "sql-server": ["sql1.domain.com"],
        "sql-reporting-server": ["ssrs1.domain.com"]
    }
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = $PSScriptRoot,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerConfig = (Join-Path $PSScriptRoot "servers.json"),
    
    [Parameter(Mandatory=$false)]
    [bool]$BackupConfigs = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$TestMode = $false
)

# Initialize logging
$LogPath = Join-Path $PSScriptRoot "LOGS"
$LogFile = Join-Path $LogPath "Deploy-DatadogConfigs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Create logs directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Start transcript logging
Start-Transcript -Path $LogFile -Append

try {
    Write-Host "=== SCCM Datadog Configuration Deployment ===" -ForegroundColor Cyan
    Write-Host "Started: $(Get-Date)" -ForegroundColor Gray
    Write-Host "Config Path: $ConfigPath" -ForegroundColor Gray
    Write-Host "Server Config: $ServerConfig" -ForegroundColor Gray
    Write-Host "Test Mode: $TestMode" -ForegroundColor Gray
    Write-Host ""

    # Validate configuration path
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration path not found: $ConfigPath"
    }

    # Validate server configuration file
    if (-not (Test-Path $ServerConfig)) {
        throw "Server configuration file not found: $ServerConfig"
    }

    # Load server configuration
    Write-Host "Loading server configuration..." -ForegroundColor Yellow
    $Servers = Get-Content $ServerConfig -Raw | ConvertFrom-Json
    
    # Define role configurations
    $RoleConfigs = @{
        "site-server" = @{
            Path = "site-server"
            Description = "SCCM Primary Site Server"
        }
        "management-point" = @{
            Path = "management-point"
            Description = "SCCM Management Point"
        }
        "distribution-point" = @{
            Path = "distribution-point"
            Description = "SCCM Distribution Point"
        }
        "sql-server" = @{
            Path = "sql-server"
            Description = "SCCM SQL Database Server"
        }
        "sql-reporting-server" = @{
            Path = "sql-reporting-server"
            Description = "SQL Reporting Services Server"
        }
    }

    # Datadog paths on target servers
    $DatadogPaths = @{
        Config = "C:\ProgramData\Datadog\datadog.yaml"
        ConfDir = "C:\ProgramData\Datadog\conf.d"
        SystemProbe = "C:\ProgramData\Datadog\system-probe.yaml"
        BackupDir = "C:\ProgramData\Datadog\backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }

    $DeploymentResults = @()
    $TotalServers = 0
    $SuccessfulDeployments = 0

    # Process each server role
    foreach ($Role in $RoleConfigs.Keys) {
        if (-not $Servers.$Role) {
            Write-Host "No servers defined for role: $Role" -ForegroundColor Yellow
            continue
        }

        $RoleConfig = $RoleConfigs[$Role]
        $RolePath = Join-Path $ConfigPath $RoleConfig.Path
        
        # Validate role configuration path
        if (-not (Test-Path $RolePath)) {
            Write-Warning "Configuration path not found for role $Role`: $RolePath"
            continue
        }

        Write-Host "`n--- Processing $($RoleConfig.Description) ---" -ForegroundColor Green
        Write-Host "Servers: $($Servers.$Role -join ', ')" -ForegroundColor Gray

        foreach ($Server in $Servers.$Role) {
            $TotalServers++
            Write-Host "`nDeploying to: $Server" -ForegroundColor Cyan
            
            try {
                # Test server connectivity
                if (-not (Test-Connection -ComputerName $Server -Count 1 -Quiet)) {
                    throw "Server not reachable: $Server"
                }

                # Create remote session for file operations
                $Session = New-PSSession -ComputerName $Server -ErrorAction Stop
                
                try {
                    # Create backup directory on remote server if backup is enabled
                    if ($BackupConfigs -and -not $TestMode) {
                        Invoke-Command -Session $Session -ScriptBlock {
                            param($BackupPath)
                            if (-not (Test-Path $BackupPath)) {
                                New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
                            }
                        } -ArgumentList $DatadogPaths.BackupDir
                        Write-Host "  Created backup directory" -ForegroundColor Gray
                    }

                    # Backup existing configurations
                    if ($BackupConfigs -and -not $TestMode) {
                        $FilesToBackup = @(
                            $DatadogPaths.Config,
                            $DatadogPaths.SystemProbe
                        )
                        
                        foreach ($File in $FilesToBackup) {
                            Invoke-Command -Session $Session -ScriptBlock {
                                param($SourceFile, $BackupDir)
                                if (Test-Path $SourceFile) {
                                    $FileName = Split-Path $SourceFile -Leaf
                                    Copy-Item $SourceFile (Join-Path $BackupDir $FileName) -Force
                                }
                            } -ArgumentList $File, $DatadogPaths.BackupDir
                        }
                        Write-Host "  Backed up existing configurations" -ForegroundColor Gray
                    }

                    # Deploy main datadog.yaml
                    $LocalDatadogConfig = Join-Path $RolePath "datadog.yaml"
                    if (Test-Path $LocalDatadogConfig) {
                        if (-not $TestMode) {
                            Copy-Item $LocalDatadogConfig -Destination $DatadogPaths.Config -ToSession $Session -Force
                        }
                        Write-Host "  Deployed: datadog.yaml" -ForegroundColor Green
                    }

                    # Deploy system-probe.yaml (common configuration)
                    $SystemProbeConfig = Join-Path $ConfigPath "common\system-probe.yaml"
                    if (Test-Path $SystemProbeConfig) {
                        if (-not $TestMode) {
                            Copy-Item $SystemProbeConfig -Destination $DatadogPaths.SystemProbe -ToSession $Session -Force
                        }
                        Write-Host "  Deployed: system-probe.yaml" -ForegroundColor Green
                    }

                    # Deploy conf.d configurations
                    $ConfDPath = Join-Path $RolePath "conf.d"
                    if (Test-Path $ConfDPath) {
                        # Get all configuration directories
                        $ConfigDirs = Get-ChildItem $ConfDPath -Directory
                        
                        foreach ($ConfigDir in $ConfigDirs) {
                            $RemoteConfPath = Join-Path $DatadogPaths.ConfDir $ConfigDir.Name
                            
                            # Create remote directory if it doesn't exist
                            if (-not $TestMode) {
                                Invoke-Command -Session $Session -ScriptBlock {
                                    param($DirPath)
                                    if (-not (Test-Path $DirPath)) {
                                        New-Item -Path $DirPath -ItemType Directory -Force | Out-Null
                                    }
                                } -ArgumentList $RemoteConfPath
                                
                                # Copy configuration files
                                $ConfigFiles = Get-ChildItem $ConfigDir.FullName -File
                                foreach ($ConfigFile in $ConfigFiles) {
                                    $RemoteFilePath = Join-Path $RemoteConfPath $ConfigFile.Name
                                    Copy-Item $ConfigFile.FullName -Destination $RemoteFilePath -ToSession $Session -Force
                                }
                            }
                            Write-Host "  Deployed: conf.d\$($ConfigDir.Name)" -ForegroundColor Green
                        }
                    }

                    $SuccessfulDeployments++
                    $DeploymentResults += [PSCustomObject]@{
                        Server = $Server
                        Role = $Role
                        Status = "Success"
                        Message = "Configuration deployed successfully"
                    }
                    
                    Write-Host "  Deployment completed successfully" -ForegroundColor Green

                } finally {
                    # Clean up remote session
                    Remove-PSSession $Session -ErrorAction SilentlyContinue
                }

            } catch {
                Write-Error "Failed to deploy to $Server`: $($_.Exception.Message)"
                $DeploymentResults += [PSCustomObject]@{
                    Server = $Server
                    Role = $Role
                    Status = "Failed"
                    Message = $_.Exception.Message
                }
            }
        }
    }

    # Display deployment summary
    Write-Host "`n=== Deployment Summary ===" -ForegroundColor Cyan
    Write-Host "Total Servers: $TotalServers" -ForegroundColor Gray
    Write-Host "Successful: $SuccessfulDeployments" -ForegroundColor Green
    Write-Host "Failed: $($TotalServers - $SuccessfulDeployments)" -ForegroundColor Red
    Write-Host "Test Mode: $TestMode" -ForegroundColor Gray

    # Display detailed results
    if ($DeploymentResults.Count -gt 0) {
        Write-Host "`n--- Detailed Results ---" -ForegroundColor Yellow
        $DeploymentResults | Format-Table -AutoSize
    }

    # Save results to file
    $ResultsFile = Join-Path $LogPath "deployment-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $DeploymentResults | ConvertTo-Json -Depth 2 | Out-File $ResultsFile -Encoding UTF8
    Write-Host "Results saved to: $ResultsFile" -ForegroundColor Gray

    Write-Host "`nCompleted: $(Get-Date)" -ForegroundColor Gray

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    throw
} finally {
    # Stop transcript logging
    Stop-Transcript
}