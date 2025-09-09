<#
.SYNOPSIS
    Test script for Repair-YamlIndentation.ps1 functionality

.DESCRIPTION
    Creates test YAML files with various indentation issues to demonstrate
    the repair script's capabilities.

.EXAMPLE
    .\Test-YamlRepair.ps1
    Creates test files and runs the repair script
#>

[CmdletBinding()]
param()

# Create test directory
$testDir = Join-Path (Get-Location) "yaml-test"
if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "Creating test YAML files with indentation issues..." -ForegroundColor Yellow

# Test file 1: Mixed tabs and spaces
$mixedContent = @"
# Test file with mixed indentation
config:
	database:  # This line uses tabs
  	host: localhost
    	port: 5432
  logging:
    level: info
	format: json
"@

$mixedContent | Set-Content -Path (Join-Path $testDir "mixed-indentation.yaml") -Encoding UTF8

# Test file 2: Inconsistent spacing
$inconsistentContent = @"
# Test file with inconsistent spacing
server:
   host: localhost
     port: 8080
       ssl: true
  timeout: 30
    retries: 3
"@

$inconsistentContent | Set-Content -Path (Join-Path $testDir "inconsistent-spacing.yaml") -Encoding UTF8

# Test file 3: Only tabs
$tabsContent = @"
# Test file with only tabs
application:
	name: test-app
	version: 1.0.0
	dependencies:
		- package1
		- package2
	settings:
		debug: true
		cache:
			enabled: true
			ttl: 3600
"@

$tabsContent | Set-Content -Path (Join-Path $testDir "tabs-only.yaml") -Encoding UTF8

# Test file 4: Already correct (should not be modified)
$correctContent = @"
# Test file with correct indentation
service:
  name: web-service
  port: 3000
  config:
    database:
      host: db.example.com
      port: 5432
    cache:
      enabled: true
      ttl: 300
"@

$correctContent | Set-Content -Path (Join-Path $testDir "correct-indentation.yaml") -Encoding UTF8

Write-Host "Test files created in: $testDir" -ForegroundColor Green

# Show original files
Write-Host "`nOriginal files content:" -ForegroundColor Cyan
Get-ChildItem $testDir -Filter "*.yaml" | ForEach-Object {
    Write-Host "`n--- $($_.Name) ---" -ForegroundColor Magenta
    Get-Content $_.FullName | ForEach-Object { 
        $line = $_
        # Show tabs as [TAB] for visibility
        $line = $line -replace "`t", "[TAB]"
        Write-Host $line
    }
}

# Run the repair script
Write-Host "`nRunning Repair-YamlIndentation.ps1..." -ForegroundColor Yellow
$repairScript = Join-Path (Get-Location) "Repair-YamlIndentation.ps1"

if (Test-Path $repairScript) {
    & $repairScript -Path $testDir -BackupPath (Join-Path $testDir "backups") -Recurse -Force
    
    # Show repaired files
    Write-Host "`nRepaired files content:" -ForegroundColor Cyan
    Get-ChildItem $testDir -Filter "*.yaml" | ForEach-Object {
        Write-Host "`n--- $($_.Name) (REPAIRED) ---" -ForegroundColor Green
        Get-Content $_.FullName | Write-Host
    }
    
    # Show backup directory structure
    $backupDir = Join-Path $testDir "backups"
    if (Test-Path $backupDir) {
        Write-Host "`nBackup directory structure:" -ForegroundColor Cyan
        Get-ChildItem $backupDir -Recurse | ForEach-Object {
            Write-Host "  $($_.FullName.Replace($backupDir, ''))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Repair script not found: $repairScript" -ForegroundColor Red
    Write-Host "Please ensure Repair-YamlIndentation.ps1 is in the current directory." -ForegroundColor Red
}

Write-Host "`nTest completed. Test files are in: $testDir" -ForegroundColor Green
Write-Host "You can examine the before/after files and backups manually." -ForegroundColor Yellow