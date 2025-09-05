# PowerShell script to automate Datadog Agent installation
# Run as Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("site-server", "management-point", "distribution-point", "sql-sccm-database", "sql-reporting-server")]
    [string]$ServerRole,
    
    [string]$DatadogSite = "datadoghq.com",
    
    [string]$SqlPassword = ""
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting Datadog Agent installation for $ServerRole" -ForegroundColor Green

# Create temp directory if not exists
$tempDir = "C:\temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Download Datadog Agent
Write-Host "Downloading Datadog Agent..." -ForegroundColor Yellow
$agentUrl = "https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi"
$agentPath = Join-Path $tempDir "datadog-agent.msi"

try {
    Start-BitsTransfer -Source $agentUrl -Destination $agentPath
} catch {
    Write-Error "Failed to download Datadog Agent: $_"
    exit 1
}

# Install Datadog Agent
Write-Host "Installing Datadog Agent..." -ForegroundColor Yellow
$installArgs = "/i `"$agentPath`" APIKEY=`"$ApiKey`" SITE=`"$DatadogSite`" /qn"
Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow

# Wait for installation to complete
Start-Sleep -Seconds 10

# Stop Datadog Agent
Write-Host "Stopping Datadog Agent service..." -ForegroundColor Yellow
Stop-Service -Name "DatadogAgent" -Force -ErrorAction SilentlyContinue

# Copy configuration files
Write-Host "Deploying configuration files for $ServerRole..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configSource = Join-Path $scriptDir $ServerRole
$configDest = "C:\ProgramData\Datadog"

if (Test-Path $configSource) {
    Copy-Item -Path "$configSource\*" -Destination $configDest -Recurse -Force
} else {
    Write-Error "Configuration directory not found: $configSource"
    exit 1
}

# Update API key in configuration
Write-Host "Updating configuration with API key..." -ForegroundColor Yellow
$datadogYaml = Join-Path $configDest "datadog.yaml"
if (Test-Path $datadogYaml) {
    $content = Get-Content $datadogYaml
    $content = $content -replace 'YOUR_API_KEY_HERE', $ApiKey
    $content = $content -replace 'sccm-.*-server', $env:COMPUTERNAME
    Set-Content -Path $datadogYaml -Value $content
}

# Update SQL password if provided
if ($SqlPassword -and ($ServerRole -like "sql-*")) {
    Write-Host "Updating SQL Server configuration..." -ForegroundColor Yellow
    $sqlConfig = Join-Path $configDest "conf.d\sqlserver.d\conf.yaml"
    if (Test-Path $sqlConfig) {
        $content = Get-Content $sqlConfig
        $content = $content -replace 'YOUR_PASSWORD_HERE', $SqlPassword
        Set-Content -Path $sqlConfig -Value $content
    }
}

# Start Datadog Agent
Write-Host "Starting Datadog Agent service..." -ForegroundColor Yellow
Start-Service -Name "DatadogAgent"

# Wait for service to start
Start-Sleep -Seconds 5

# Verify installation
Write-Host "`nVerifying installation..." -ForegroundColor Yellow
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status

Write-Host "`nDatadog Agent installation completed successfully!" -ForegroundColor Green
Write-Host "Please check the Datadog web interface to verify metrics are being received." -ForegroundColor Cyan