<#
.SYNOPSIS
    Installs PowerShell-Yaml module for enhanced YAML validation

.DESCRIPTION
    This script checks for and optionally installs the PowerShell-Yaml module
    which provides enhanced YAML parsing and validation capabilities for the
    Repair-YamlIndentation.ps1 script.

.PARAMETER Force
    Forces installation even if module is already present

.EXAMPLE
    .\Install-YamlModule.ps1
    Checks for and installs PowerShell-Yaml module if needed

.EXAMPLE
    .\Install-YamlModule.ps1 -Force
    Forces reinstallation of the module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Write-StatusMessage {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $color = switch ($Status) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

Write-StatusMessage "PowerShell-Yaml Module Installation Script" "Info"
Write-StatusMessage "=========================================" "Info"

# Check if module is already installed
$module = Get-Module -ListAvailable -Name "PowerShell-Yaml" -ErrorAction SilentlyContinue

if ($module -and -not $Force) {
    Write-StatusMessage "PowerShell-Yaml module is already installed (Version: $($module.Version))" "Success"
    Write-StatusMessage "Use -Force parameter to reinstall" "Info"
    
    # Test the module
    try {
        Import-Module PowerShell-Yaml -ErrorAction Stop
        $testYaml = "test: value`narray:`n  - item1`n  - item2"
        $parsed = ConvertFrom-Yaml -Yaml $testYaml
        Write-StatusMessage "Module test successful - YAML parsing works correctly" "Success"
    }
    catch {
        Write-StatusMessage "Module test failed: $($_.Exception.Message)" "Error"
        Write-StatusMessage "Consider reinstalling with -Force parameter" "Warning"
    }
    
    exit 0
}

if ($module -and $Force) {
    Write-StatusMessage "Forcing reinstallation of PowerShell-Yaml module..." "Warning"
}

# Check PowerShell Gallery availability
try {
    $gallery = Get-PSRepository -Name "PSGallery" -ErrorAction Stop
    if ($gallery.InstallationPolicy -ne "Trusted") {
        Write-StatusMessage "PSGallery is not trusted. Setting as trusted for this session..." "Warning"
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    }
}
catch {
    Write-StatusMessage "Cannot access PowerShell Gallery: $($_.Exception.Message)" "Error"
    exit 1
}

# Install the module
try {
    Write-StatusMessage "Installing PowerShell-Yaml module from PowerShell Gallery..." "Info"
    
    $installParams = @{
        Name = "PowerShell-Yaml"
        Scope = "CurrentUser"
        Force = $Force
        AllowClobber = $true
    }
    
    Install-Module @installParams
    
    Write-StatusMessage "PowerShell-Yaml module installed successfully" "Success"
    
    # Test the installation
    Import-Module PowerShell-Yaml -ErrorAction Stop
    $testYaml = @"
# Test YAML content
config:
  database:
    host: localhost
    port: 5432
  features:
    - authentication
    - logging
    - monitoring
"@
    
    $parsed = ConvertFrom-Yaml -Yaml $testYaml
    Write-StatusMessage "Installation test successful - YAML parsing works correctly" "Success"
    
    # Show module information
    $installedModule = Get-Module -Name "PowerShell-Yaml"
    Write-StatusMessage "Installed Version: $($installedModule.Version)" "Info"
    Write-StatusMessage "Module Path: $($installedModule.ModuleBase)" "Info"
    
    Write-StatusMessage "" "Info"
    Write-StatusMessage "The Repair-YamlIndentation.ps1 script can now use enhanced YAML validation." "Success"
    Write-StatusMessage "Use the -Validate parameter for comprehensive syntax checking." "Info"
}
catch {
    Write-StatusMessage "Failed to install PowerShell-Yaml module: $($_.Exception.Message)" "Error"
    Write-StatusMessage "The Repair-YamlIndentation.ps1 script will still work with basic validation." "Warning"
    exit 1
}