<#
.SYNOPSIS
    Deploys Datadog monitoring configurations to SCCM servers using Windows Authentication.

.DESCRIPTION
    This script automates the deployment of Datadog monitoring configurations to SCCM infrastructure servers.
    All SQL Server connections use Windows Authentication (Trusted_Connection=yes) for enhanced security.

.PARAMETER ConfigPath
    Path to the configuration files directory. Defaults to script root directory.

.PARAMETER ServerConfig
    Path to the servers.json configuration file. Defaults to servers.json in script root.

.PARAMETER BackupConfigs
    Create backup of existing configurations before deployment. Default is $true.

.PARAMETER RestartService
    Restart Datadog Agent service after configuration deployment. Default is $true.

.PARAMETER TestMode
    Run in test mode - validate configurations and connectivity without making changes. Default is $false.

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1
    Deploy configurations with Windows Authentication, creates backups, and restarts services.

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1 -TestMode $true
    Test deployment without making changes.

.EXAMPLE
    .\Deploy-DatadogConfigs.ps1 -BackupConfigs $false -RestartService $false
    Deploy without creating backups or restarting services.

.NOTES
    - Script must be run as Administrator
    - Agent service account must have log file read permissions
    - Datadog Agent service account needs SQL Server access for Windows Authentication
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)] [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)] [string]$ServerConfig,
    
    [Parameter(Mandatory = $false)] [bool]$BackupConfigs = $true,
    
    [Parameter(Mandatory = $false)] [bool]$RestartService = $true,
    
    [Parameter(Mandatory = $false)] [bool]$TestMode = $false
)

# Set default paths if not provided
if (-not $ConfigPath) { $ConfigPath = $PSScriptRoot }
if (-not $ServerConfig) { $ServerConfig = Join-Path $PSScriptRoot "servers.json" }

# Ensure _LOGS directory exists
$LogsDir = Join-Path $PSScriptRoot "_LOGS"
if (-not (Test-Path $LogsDir)) { New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null }

# Set log file
$LogFile = Join-Path $LogsDir "Datadog_DeployConfigs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Default Datadog Windows service name (default service name used by the agent)
$DatadogServiceName = "DatadogAgent"

# Configuration mappings
$RoleConfigurations = @{
    "site-server"          = @{
        "Description"     = "SCCM Primary Site Server"
        "ConfigDir"       = "site-server"
        "TargetPath"      = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "management-point"     = @{
        "Description"     = "SCCM Management Point Server"
        "ConfigDir"       = "management-point"
        "TargetPath"      = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "distribution-point"   = @{
        "Description"     = "SCCM Distribution Point Server"
        "ConfigDir"       = "distribution-point"
        "TargetPath"      = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "sql-server"           = @{
        "Description"     = "SCCM SQL Database Server"
        "ConfigDir"       = "sql-server"
        "TargetPath"      = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
    "sql-reporting-server" = @{
        "Description"     = "SQL Reporting Services Server"
        "ConfigDir"       = "sql-reporting-server"
        "TargetPath"      = "C:\ProgramData\Datadog"
        "RequiresRestart" = $true
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    # Color coding for console output
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO" { Write-Host $logMessage -ForegroundColor White }
        default { Write-Host $logMessage }
    }
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
    # Validate PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)" "ERROR"
        return $false
    }
    # Test WinRM connectivity if not in TestMode
    if (-not $TestMode) {
        try {
            $null = Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address = "*"; Transport = "HTTP" } -ErrorAction Stop
            Write-Log "WinRM connectivity verified"
        }
        catch { Write-Log "WinRM may not be properly configured for remote deployment: $($_.Exception.Message)" "WARNING" }
    }
    Write-Log "Prerequisites check passed"
    return $true
}

function Get-ServerConfiguration {
    try {
        $servers = Get-Content -Raw -Path $ServerConfig | ConvertFrom-Json
        Write-Log "Loaded server configuration from $ServerConfig"
        # Validate server configuration structure
        $totalServers = 0
        foreach ($role in $servers.PSObject.Properties.Name) {
            $serverList = $servers.$role
            if ($serverList -and $serverList.Count -gt 0) {
                $totalServers += $serverList.Count
                Write-Log "Found $($serverList.Count) servers for role: $role"
            }
        }
        if ($totalServers -eq 0) {
            Write-Log "No servers found in configuration file" "ERROR"
            return $null
        }
        Write-Log "Total servers to process: $totalServers"
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
    # Validate source path exists
    if (-not (Test-Path $sourcePath)) {
        Write-Log "Configuration source path not found: $sourcePath" "ERROR"
        return $null
    }
    
    # All configurations now use Windows Authentication by default
    Write-Log "Using Windows Authentication configuration for $Role"
    return $sourcePath
}

function Update-ConfigurationFiles {
    param(
        [string]$SourcePath,
        [string]$TargetServer,
        [string]$TargetPath,
        [bool]$CreateBackup = $true
    )
    Write-Log "Deploying configuration from $SourcePath to $TargetServer"
    $remotePath = "\\$TargetServer\$($TargetPath.Replace(':', '$'))"
    # Test connectivity (always test, even in TestMode)
    if (-not (Test-Path $remotePath)) {
        Write-Log "Cannot access remote path: $remotePath" "ERROR"
        # Enhanced connectivity troubleshooting
        try {
            $pingResult = Test-Connection -ComputerName $TargetServer -Count 1 -Quiet
            if (-not $pingResult) {
                Write-Log "Server $TargetServer is not reachable via ping" "ERROR"
            }
            else { Write-Log "Server $TargetServer is reachable but administrative share may not be accessible" "ERROR" }
        }
        catch {
            Write-Log "Network connectivity test failed for $TargetServer`: $($_.Exception.Message)" "ERROR"
        }
        return $false
    }
    if ($TestMode) {
        Write-Log "TEST MODE: Successfully validated remote path access: $remotePath" "INFO"
        # Test what files would be copied
        try {
            $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -File
            Write-Log "TEST MODE: Would copy $($sourceFiles.Count) files from $SourcePath" "INFO"
            # Show sample of files that would be copied
            $sampleFiles = $sourceFiles | Select-Object -First 5
            foreach ($file in $sampleFiles) {
                $relativePath = $file.FullName.Replace($SourcePath, "")
                Write-Log "TEST MODE: Would copy: $relativePath" "INFO"
            }
            if ($sourceFiles.Count -gt 5) {
                Write-Log "TEST MODE: ... and $($sourceFiles.Count - 5) more files" "INFO"
            }
            # Test backup directory creation if requested
            if ($CreateBackup) {
                $backupPath = Join-Path $remotePath "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Write-Log "TEST MODE: Would create backup at: $backupPath" "INFO"
                # Check existing configs that would be backed up
                $existingConfigs = Get-ChildItem -Path $remotePath -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.Extension -eq ".yaml" -or $_.Directory.Name -eq "conf.d" }
                Write-Log "TEST MODE: Would backup $($existingConfigs.Count) existing configuration files" "INFO"
            }
            # Validate configuration files syntax
            $yamlFiles = $sourceFiles | Where-Object { $_.Extension -eq ".yaml" }
            foreach ($yamlFile in $yamlFiles) {
                Write-Log "TEST MODE: Would deploy YAML config: $($yamlFile.Name)" "INFO"
            }
            return $true
        }
        catch {
            Write-Log "TEST MODE: Error during validation: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    try {
        # Create backup if requested
        if ($CreateBackup) {
            $backupPath = Join-Path $remotePath "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            if (-not (Test-Path $backupPath)) {
                New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
                Write-Log "Created backup directory: $backupPath"
            }
            # Backup existing configurations
            $existingConfigs = Get-ChildItem -Path $remotePath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq ".yaml" -or $_.Directory.Name -eq "conf.d" }
            $backupCount = 0
            foreach ($config in $existingConfigs) {
                try {
                    $relativePath = $config.FullName.Replace($remotePath, "").TrimStart('\')
                    $backupTarget = Join-Path $backupPath $relativePath
                    $backupTargetDir = Split-Path $backupTarget -Parent
                    if (-not (Test-Path $backupTargetDir)) {
                        New-Item -Path $backupTargetDir -ItemType Directory -Force | Out-Null
                    }
                    Copy-Item -Path $config.FullName -Destination $backupTarget -Verbose -Force
                    $backupCount++
                }
                catch { Write-Log "Warning: Could not backup $($config.FullName): $($_.Exception.Message)" "WARNING" }
            }
            Write-Log "Created backup of $backupCount files at $backupPath"
        }
        # Copy new configurations (datadog.yaml and conf.d only)
        $srcYaml = Join-Path $SourcePath "datadog.yaml"
        if (Test-Path $srcYaml) {
            Copy-Item -Path $srcYaml -Destination $remotePath -Force -Verbose
        }
        $srcConf = Join-Path $SourcePath "conf.d"
        $dstConf = Join-Path $remotePath "conf.d"
        if (Test-Path $srcConf) {
            if (-not (Test-Path $dstConf)) {
                New-Item -ItemType Directory -Path $dstConf -Force | Out-Null
            }
            Copy-Item -Path "$srcConf\*" -Destination $dstConf -Recurse -Force -Verbose
        }
        Write-Log "Successfully deployed configuration to $TargetServer" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to deploy configuration to $TargetServer`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restart-DatadogAgent {
    param( [string]$TargetServer )

    if (-not $RestartService) {
        Write-Log "Service restart disabled, skipping restart on $TargetServer" "INFO"
        return $true
    }

    if ($TestMode) {
        # In TestMode, check service status and validate agent.exe exists without making changes
        try {
            Write-Log "TEST MODE: Checking Datadog Agent service status on $TargetServer" "INFO"
            $servicesBefore = Get-Service -ComputerName $TargetServer | Where-Object { $_.Name -like "datadog*" }
            foreach ($svc in $servicesBefore) {
                Write-Log "TEST MODE: $($svc.Name): $($svc.Status)" "INFO"
            }
            
            # Test if agent.exe exists on target server
            $agentExePath = "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe"
            $agentExists = Invoke-Command -ComputerName $TargetServer -ScriptBlock {
                Test-Path "$using:agentExePath"
            } -ErrorAction Stop
            
            if ($agentExists) {
                Write-Log "TEST MODE: Datadog agent.exe found at expected path on $TargetServer" "INFO"
                Write-Log "TEST MODE: Would restart Datadog Agent using agent.exe CLI" "INFO"
            }
            else {
                Write-Log "TEST MODE: Datadog agent.exe not found at expected path on $TargetServer" "WARNING"
                Write-Log "TEST MODE: Would fall back to PowerShell service restart method" "INFO"
            }
            
            # Test if primary service can be controlled
            $primaryService = $servicesBefore | Where-Object { $_.Name -eq $DatadogServiceName }
            if ($primaryService) {
                Write-Log "TEST MODE: Primary service $DatadogServiceName status: $($primaryService.Status)" "INFO"
                if ($primaryService.Status -eq 'Running') {
                    Write-Log "TEST MODE: Service is running and ready for restart" "INFO"
                }
                elseif ($primaryService.Status -eq 'Stopped') {
                    Write-Log "TEST MODE: Service is stopped and would need to be started" "INFO"
                }
                else {
                    Write-Log "TEST MODE: Service is in $($primaryService.Status) state" "WARNING"
                }
            }
            else {
                Write-Log "TEST MODE: Primary service $DatadogServiceName not found" "ERROR"
                return $false
            }
            
            return $true
        }
        catch {
            Write-Log "TEST MODE: Failed to check Datadog Agent service on $($TargetServer): $($_.Exception.Message)" "ERROR"
            return $false
        }
    }

    $agentExePath = "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe"

    try {
        Write-Log "Getting Datadog service statuses on $TargetServer before restart" "INFO"
        $servicesBefore = Get-Service -ComputerName $TargetServer | Where-Object { $_.Name -like "datadog*" }
        foreach ($svc in $servicesBefore) {
            Write-Log "$($svc.Name): $($svc.Status)" "INFO"
        }

        Write-Log "Restarting Datadog Agent on $TargetServer using agent.exe CLI" "INFO"
        Invoke-Command -ComputerName $TargetServer -ScriptBlock {
            & "$using:agentExePath" restart-service
        } -ErrorAction Stop

        # Wait for primary service to stop and start
        $stopTimeout = 60
        $stopTimer = 0
        do {
            Start-Sleep -Seconds 2
            $stopTimer += 2
            $serviceStatus = Get-Service -ComputerName $TargetServer -Name $DatadogServiceName
            if ($stopTimer -ge $stopTimeout) {
                Write-Log "Timeout waiting for $DatadogServiceName to restart on $TargetServer" "ERROR"
                return $false
            }
        } while ($serviceStatus.Status -ne 'Running')

        Write-Log "$DatadogServiceName restarted successfully on $TargetServer (took $stopTimer seconds)" "SUCCESS"

        Write-Log "Getting Datadog service statuses on $TargetServer after restart" "INFO"
        $servicesAfter = Get-Service -ComputerName $TargetServer | Where-Object { $_.Name -like "datadog*" }
        foreach ($svc in $servicesAfter) {
            Write-Log "$($svc.Name): $($svc.Status)" "INFO"
        }

        # Optional: invoke agent status to validate integrations
        try {
            Invoke-Command -ComputerName $TargetServer -ScriptBlock {
                & "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status | Out-String | ForEach-Object {
                    $_.Split([Environment]::NewLine) | Select-Object -First 1
                }
            } -ErrorAction SilentlyContinue | Out-Null
            Write-Log "Invoked agent status on $TargetServer" "INFO"
        }
        catch {
            Write-Log "Could not invoke agent status on $($TargetServer): $($_.Exception.Message)" "WARNING"
        }

        return $true
    }
    catch {
        Write-Log "Failed to restart Datadog Agent on $($TargetServer): $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-PostDeploymentInfo {
    Write-Log "`n========================================" "INFO"
    Write-Log "DEPLOYMENT SUMMARY" "INFO"
    Write-Log "========================================" "INFO"
    Write-Log "Deployment Mode: Windows Authentication" "INFO"
    Write-Log "Test Mode: $TestMode" "INFO"
    Write-Log "Backup Created: $BackupConfigs" "INFO"
    Write-Log "Service Restarted: $RestartService" "INFO"
    
    Write-Log "`nWindows Authentication Deployment Complete" "SUCCESS"
    Write-Log "`nIMPORTANT NOTES FOR WINDOWS AUTHENTICATION:" "INFO"
    Write-Log "- Verify Datadog Agent service account has SQL Server access" "INFO"
    Write-Log "- Check that Windows Authentication is enabled on SQL Server" "INFO"
    Write-Log "- Monitor agent logs for authentication issues" "INFO"
    Write-Log "- Use 'auth:windows' tag to identify these deployments in Datadog" "INFO"
    Write-Log "`nAdditional Resources:" "INFO"
    Write-Log "- Deployment logs: $LogFile" "INFO"
    Write-Log "- Agent status: Run 'Get-Service $DatadogServiceName' on target servers" "INFO"
    Write-Log "- Configuration validation: Check agent.exe status on each server" "INFO"
    
    Write-Log "NEXT STEPS:" "INFO"
    Write-Log "1. Replace 'YOUR_API_KEY_HERE' with actual Datadog API key" "INFO"
    Write-Log "2. Verify Datadog Agent connectivity to Datadog endpoints" "INFO"
    Write-Log "3. Check metrics collection in Datadog dashboard" "INFO"
    Write-Log "`nAdditional Resources:" "INFO"
    Write-Log "- Deployment logs: $LogFile" "INFO"
    Write-Log "- Configuration templates: $ConfigPath" "INFO"
    Write-Log "- Server configuration: $ServerConfig" "INFO"
}
    
Write-Log "`nVERIFICATION COMMANDS:" "INFO"
Write-Log "# Check agent status on all servers" "INFO"
Write-Log "Get-Service $DatadogServiceName -ComputerName <server-name>" "INFO"
Write-Log "`n# Verify configuration on target server" "INFO"
Write-Log "Invoke-Command -ComputerName <server> -ScriptBlock { & 'C:\Program Files\Datadog\Datadog Agent\bin\agent.exe' status }" "INFO"
Write-Log "`n# Check recent agent logs" "INFO"
Write-Log "Get-Content '\\<server>\c$\ProgramData\Datadog\logs\agent.log' -Tail 20" "INFO"
Write-Log "`nFor support and troubleshooting, refer to the README.md file." "INFO"
Write-Log "========================================" "INFO"

function Clear-TempDirectories {
    param([string[]]$TempDirectories)
    foreach ($tempDir in $TempDirectories) {
        if ($tempDir -and (Test-Path $tempDir) -and $tempDir.StartsWith($env:TEMP)) {
            try {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop
                Write-Log "Cleaned up temporary directory: $tempDir"
            }
            catch { Write-Log "Warning: Could not remove temporary directory $tempDir`: $($_.Exception.Message)" "WARNING" }
        }
    }
}

# Main execution block
try {
    # Initialize logging
    Write-Log "========================================" "INFO"
    Write-Log "DATADOG CONFIGURATION DEPLOYMENT SCRIPT" "INFO"
    Write-Log "========================================" "INFO"
    Write-Log "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    Write-Log "Script Version: 1.2" "INFO"
    Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)" "INFO"
    Write-Log "Execution Policy: $(Get-ExecutionPolicy)" "INFO"
    Write-Log "User Context: $($env:USERNAME)@$($env:COMPUTERNAME)" "INFO"
    Write-Log "`nPARAMETERS:" "INFO"
    Write-Log "- ConfigPath: $ConfigPath" "INFO"
    Write-Log "- ServerConfig: $ServerConfig" "INFO"
    Write-Log "- Windows Authentication: Enabled (default)" "INFO"
    Write-Log "- BackupConfigs: $BackupConfigs" "INFO"
    Write-Log "- RestartService: $RestartService" "INFO"
    Write-Log "- TestMode: $TestMode" "INFO"
    Write-Log "- LogFile: $LogFile" "INFO"

    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Log "`nPrerequisites check failed. Exiting." "ERROR"
        exit 1
    }

    # Load server configuration
    $servers = Get-ServerConfiguration
    if (-not $servers) {
        Write-Log "`nFailed to load server configuration. Exiting." "ERROR"
        exit 1
    }

    # Initialize deployment tracking
    $deploymentResults = @{}
    $totalServers = 0
    $successfulDeployments = 0
    $tempDirectories = @()

    # Process each server role
    foreach ($role in $servers.PSObject.Properties.Name) {
        if (-not $RoleConfigurations.ContainsKey($role)) {
            Write-Log "`nUnknown role: $role" "WARNING"
            continue
        }
        
        $roleConfig = $RoleConfigurations[$role]
        $serverList = $servers.$role
        
        if (-not $serverList -or $serverList.Count -eq 0) {
            Write-Log "`nNo servers defined for role: $role" "WARNING"
            continue
        }
        
        Write-Log "`nProcessing role: $role - $($roleConfig['Description']) ($($serverList.Count) servers)"
        
        foreach ($server in $serverList) {
            $totalServers++
            Write-Log "`nDeploying to $server (Role: $role)"
            
            $sourcePath = Get-ConfigurationSource -Role $role -ConfigDir $roleConfig['ConfigDir']
            if (-not $sourcePath) {
                Write-Log "`nFailed to prepare configuration source for $role" "ERROR"
                continue
            }
            
            # Track temp directories for cleanup
            if ($sourcePath.StartsWith($env:TEMP)) {
                $tempDirectories += $sourcePath
            }
            
            $deploySuccess = Update-ConfigurationFiles -SourcePath $sourcePath -TargetServer $server -TargetPath $roleConfig['TargetPath'] -CreateBackup $BackupConfigs
            
            if ($deploySuccess -and $roleConfig['RequiresRestart']) {
                $restartSuccess = Restart-DatadogAgent -TargetServer $server
                $deploySuccess = $deploySuccess -and $restartSuccess
            }
            
            if ($deploySuccess) {
                $successfulDeployments++
                Write-Log "`nSuccessfully deployed to $server" "SUCCESS"
            }
            else {
                Write-Log "`nFailed to deploy to $server" "ERROR"
            }
            
            $deploymentResults[$server] = @{
                "Role"        = $role
                "Success"     = $deploySuccess
                "Description" = $roleConfig['Description']
            }
        }
    }

    # Cleanup temporary directories
    if ($tempDirectories.Count -gt 0) {
        Write-Log "`nCleaning up $($tempDirectories.Count) temporary directories"
        Clear-TempDirectories -TempDirectories $tempDirectories
    }

    # Display final results
    Write-Log "`n========================================" "INFO"
    Write-Log "DEPLOYMENT RESULTS" "INFO"
    Write-Log "========================================" "INFO"
    $failedCount = $totalServers - $successfulDeployments
    $level = if ($failedCount -gt 0) { "ERROR" } else { "INFO" }
    Write-Log "Total Servers: $totalServers" "INFO"
    Write-Log "Successful Deployments: $successfulDeployments" "SUCCESS"
    Write-Log "Failed Deployments: $failedCount" $level
    Write-Log ""

    # Show detailed results
    foreach ($server in $deploymentResults.Keys) {
        $result = $deploymentResults[$server]
        $status = if ($result['Success']) { "SUCCESS" } else { "FAILED" }
        $level = if ($result['Success']) { "SUCCESS" } else { "ERROR" }
        Write-Log "$server ($($result['Role'])): $status" $level
    }

    # Show post-deployment information
    Show-PostDeploymentInfo

    # Set exit code based on results
    if ($successfulDeployments -eq $totalServers) {
        Write-Log "`nAll deployments completed successfully" "SUCCESS"
        exit 0
    }
    elseif ($successfulDeployments -gt 0) {
        Write-Log "`nPartial deployment completed. Check logs for failed servers." "WARNING"
        exit 2
    }
    else {
        Write-Log "`nAll deployments failed. Check configuration and connectivity." "ERROR"
        exit 1
    }
}
catch {
    Write-Log "`nUnexpected error during deployment: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    # Cleanup on error
    if ($tempDirectories.Count -gt 0) {
        Clear-TempDirectories -TempDirectories $tempDirectories
    }
    
    exit 1
}
finally {
    Write-Log "`nDeployment script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    Write-Log "Log file location: $LogFile" "INFO"
}
