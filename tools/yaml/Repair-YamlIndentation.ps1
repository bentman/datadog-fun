<#
.SYNOPSIS
    Repairs YAML file indentation by converting tabs to spaces and standardizing spacing.

.DESCRIPTION
    This script scans directories for YAML files (.yml, .yaml) and corrects indentation issues:
    - Converts tabs to spaces
    - Standardizes indentation to 2 spaces per level
    - Preserves comments and file structure
    - Creates backups maintaining original folder structure
    - Validates YAML syntax before and after changes

.PARAMETER Path
    The root path to scan for YAML files. Defaults to current directory.

.PARAMETER BackupPath
    The path where backups will be stored. Defaults to ".\yaml-backups"

.PARAMETER IndentSize
    Number of spaces per indentation level. Defaults to 2.

.PARAMETER Recurse
    Recursively scan subdirectories for YAML files.

.PARAMETER WhatIf
    Shows what would be done without making changes.

.PARAMETER Force
    Overwrites existing backup files without prompting.

.PARAMETER Validate
    Validates YAML syntax using PowerShell-Yaml module if available.

.EXAMPLE
    .\Repair-YamlIndentation.ps1 -Path "C:\MyProject" -Recurse
    Repairs all YAML files in C:\MyProject and subdirectories

.EXAMPLE
    .\Repair-YamlIndentation.ps1 -Path "." -BackupPath "C:\Backups\yaml" -IndentSize 4
    Repairs YAML files in current directory with 4-space indentation

.EXAMPLE
    .\Repair-YamlIndentation.ps1 -WhatIf -Recurse
    Shows what files would be processed without making changes

.NOTES
    Author: OpenHands AI Assistant
    Version: 1.0.0
    Requires: PowerShell 5.1 or later
    
    This script is designed to be standalone and does not require external modules,
    though it can optionally use PowerShell-Yaml for validation if available.

.LINK
    https://github.com/bentman/datadog-fun
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string]$BackupPath = (Join-Path (Get-Location).Path "yaml-backups"),
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(2, 8)]
    [int]$IndentSize = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$Validate
)

# Script-level variables
$script:ProcessedFiles = 0
$script:ModifiedFiles = 0
$script:ErrorFiles = 0
$script:BackupFiles = 0

# YAML file extensions to process
$YamlExtensions = @('*.yml', '*.yaml')

#region Helper Functions

function Write-LogMessage {
    <#
    .SYNOPSIS
        Writes formatted log messages with timestamps
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message -ForegroundColor $color
}

function Test-YamlSyntax {
    <#
    .SYNOPSIS
        Tests YAML syntax using basic parsing
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Basic YAML syntax validation without external modules
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        # Check for basic YAML structure issues
        $lines = $content -split "`n"
        $indentStack = @()
        $lineNumber = 0
        
        foreach ($line in $lines) {
            $lineNumber++
            $trimmedLine = $line.Trim()
            
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
                continue
            }
            
            # Check for tabs (should not exist after our processing)
            if ($line.Contains("`t")) {
                throw "Line $lineNumber contains tab characters"
            }
            
            # Basic indentation validation
            $leadingSpaces = $line.Length - $line.TrimStart(' ').Length
            if ($leadingSpaces % $IndentSize -ne 0) {
                throw "Line $lineNumber has invalid indentation (not multiple of $IndentSize)"
            }
        }
        
        return $true
    }
    catch {
        Write-LogMessage "YAML validation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-PowerShellYamlModule {
    <#
    .SYNOPSIS
        Tests if PowerShell-Yaml module is available for advanced validation
    #>
    try {
        Import-Module PowerShell-Yaml -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-YamlSyntaxAdvanced {
    <#
    .SYNOPSIS
        Tests YAML syntax using PowerShell-Yaml module if available
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    if (-not (Test-PowerShellYamlModule)) {
        return Test-YamlSyntax -FilePath $FilePath
    }
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $null = ConvertFrom-Yaml -Yaml $content
        return $true
    }
    catch {
        Write-LogMessage "Advanced YAML validation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function New-BackupDirectory {
    <#
    .SYNOPSIS
        Creates backup directory structure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )
    
    $relativePath = [System.IO.Path]::GetRelativePath($Path, $SourcePath)
    $backupDir = Join-Path $BackupRoot $relativePath
    
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        Write-LogMessage "Created backup directory: $backupDir" -Level Info
    }
    
    return $backupDir
}

function Backup-YamlFile {
    <#
    .SYNOPSIS
        Creates a backup of the original YAML file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )
    
    try {
        $sourceDir = Split-Path $SourceFile -Parent
        $fileName = Split-Path $SourceFile -Leaf
        $backupDir = New-BackupDirectory -SourcePath $sourceDir -BackupRoot $BackupRoot
        $backupFile = Join-Path $backupDir $fileName
        
        if ((Test-Path $backupFile) -and -not $Force) {
            $response = Read-Host "Backup file already exists: $backupFile. Overwrite? (y/N)"
            if ($response -notmatch '^[Yy]') {
                Write-LogMessage "Skipping backup for: $SourceFile" -Level Warning
                return $false
            }
        }
        
        Copy-Item -Path $SourceFile -Destination $backupFile -Force
        $script:BackupFiles++
        Write-LogMessage "Backed up: $SourceFile -> $backupFile" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Failed to backup $SourceFile`: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Repair-YamlIndentationContent {
    <#
    .SYNOPSIS
        Repairs indentation in YAML content
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        $Lines
    )
    
    $repairedLines = @()
    $hasChanges = $false
    

    
    # Handle empty input
    if ($null -eq $Lines -or $Lines.Count -eq 0) {
        return @{
            Lines = @()
            HasChanges = $false
        }
    }
    
    # Check for problematic elements
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($null -eq $Lines[$i]) {
            $Lines[$i] = ""
        }
    }
    
    foreach ($line in $Lines) {
        $originalLine = $line
        
        # Convert tabs to spaces
        if ($line.Contains("`t")) {
            $line = $line.Replace("`t", ' ' * $IndentSize)
            $hasChanges = $true
        }
        
        # Skip empty lines - preserve as-is
        if ([string]::IsNullOrWhiteSpace($line.Trim())) {
            $repairedLines += $line
            continue
        }
        
        # Handle comments - convert tabs but preserve content and relative indentation
        if ($line.Trim().StartsWith('#')) {
            $repairedLines += $line
            continue
        }
        
        # Calculate current indentation
        $leadingSpaces = $line.Length - $line.TrimStart(' ').Length
        $content = $line.TrimStart(' ')
        
        # Normalize indentation to proper multiples
        if ($leadingSpaces -gt 0) {
            $indentLevel = [Math]::Round($leadingSpaces / $IndentSize)
            $normalizedIndent = $indentLevel * $IndentSize
            
            if ($normalizedIndent -ne $leadingSpaces) {
                $line = (' ' * $normalizedIndent) + $content
                $hasChanges = $true
            }
        }
        
        $repairedLines += $line
    }
    
    return @{
        Lines = $repairedLines
        HasChanges = $hasChanges
    }
}

function Repair-YamlFile {
    <#
    .SYNOPSIS
        Repairs a single YAML file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        Write-LogMessage "Processing: $FilePath" -Level Info
        $script:ProcessedFiles++
        
        # Read original content
        $originalContent = Get-Content -Path $FilePath -Encoding UTF8
        

        
        # Handle empty files or null content
        if ($null -eq $originalContent -or $originalContent.Count -eq 0) {
            Write-LogMessage "File is empty or null, skipping: $FilePath" -Level Info
            return
        }
        
        # Handle empty string content
        if ($originalContent -is [string] -and [string]::IsNullOrWhiteSpace($originalContent)) {
            Write-LogMessage "File contains only whitespace, skipping: $FilePath" -Level Info
            return
        }
        
        # Ensure we have an array of strings
        if ($originalContent -is [string]) {
            $originalContent = @($originalContent)
        }
        
        # Final validation before passing to function
        if ($originalContent.Count -eq 0) {
            Write-LogMessage "Content array is empty after processing, skipping: $FilePath" -Level Info
            return
        }
        
        # Convert any null elements to empty strings and ensure all elements are strings
        $cleanedContent = @()
        foreach ($line in $originalContent) {
            if ($null -eq $line) {
                $cleanedContent += ""
            } else {
                $cleanedContent += [string]$line
            }
        }
        $originalContent = $cleanedContent
        

        
        # Validate original syntax if requested
        if ($Validate) {
            Write-LogMessage "Validating original syntax..." -Level Info
            if (-not (Test-YamlSyntaxAdvanced -FilePath $FilePath)) {
                Write-LogMessage "Original file has syntax errors, skipping..." -Level Warning
                $script:ErrorFiles++
                return
            }
        }
        
        # Repair indentation
        $result = Repair-YamlIndentationContent -Lines $originalContent
        
        if (-not $result.HasChanges) {
            Write-LogMessage "No changes needed for: $FilePath" -Level Info
            return
        }
        
        if ($PSCmdlet.ShouldProcess($FilePath, "Repair YAML indentation")) {
            # Create backup
            if (-not (Backup-YamlFile -SourceFile $FilePath -BackupRoot $BackupPath)) {
                Write-LogMessage "Backup failed, skipping file: $FilePath" -Level Error
                $script:ErrorFiles++
                return
            }
            
            # Write repaired content
            $result.Lines | Set-Content -Path $FilePath -Encoding UTF8
            $script:ModifiedFiles++
            
            # Validate repaired syntax if requested
            if ($Validate) {
                Write-LogMessage "Validating repaired syntax..." -Level Info
                if (-not (Test-YamlSyntaxAdvanced -FilePath $FilePath)) {
                    Write-LogMessage "Repaired file has syntax errors, restoring backup..." -Level Error
                    $backupFile = Join-Path (New-BackupDirectory -SourcePath (Split-Path $FilePath -Parent) -BackupRoot $BackupPath) (Split-Path $FilePath -Leaf)
                    Copy-Item -Path $backupFile -Destination $FilePath -Force
                    $script:ErrorFiles++
                    return
                }
            }
            
            Write-LogMessage "Successfully repaired: $FilePath" -Level Success
        }
    }
    catch {
        Write-LogMessage "Error processing $FilePath`: $($_.Exception.Message)" -Level Error
        $script:ErrorFiles++
    }
}

#endregion

#region Main Script Logic

function Start-YamlRepair {
    <#
    .SYNOPSIS
        Main function to start the YAML repair process
    #>
    
    Write-LogMessage "Starting YAML indentation repair process" -Level Info
    Write-LogMessage "Source Path: $Path" -Level Info
    Write-LogMessage "Backup Path: $BackupPath" -Level Info
    Write-LogMessage "Indent Size: $IndentSize spaces" -Level Info
    Write-LogMessage "Recursive: $Recurse" -Level Info
    Write-LogMessage "Validation: $Validate" -Level Info
    
    # Validate source path
    if (-not (Test-Path $Path -PathType Container)) {
        Write-LogMessage "Source path does not exist or is not a directory: $Path" -Level Error
        return
    }
    
    # Create backup directory
    if (-not (Test-Path $BackupPath)) {
        try {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created backup directory: $BackupPath" -Level Success
        }
        catch {
            Write-LogMessage "Failed to create backup directory: $($_.Exception.Message)" -Level Error
            return
        }
    }
    
    # Find YAML files
    $yamlFiles = @()
    
    if ($Recurse) {
        # When recursing, we can use Include parameter
        $yamlFiles = Get-ChildItem -Path $Path -Include $YamlExtensions -File -Recurse
    } else {
        # When not recursing, we need to search for each extension separately
        foreach ($extension in $YamlExtensions) {
            $pattern = Join-Path $Path $extension
            $yamlFiles += Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue
        }
    }
    
    if ($yamlFiles.Count -eq 0) {
        Write-LogMessage "No YAML files found in: $Path" -Level Warning
        return
    }
    
    Write-LogMessage "Found $($yamlFiles.Count) YAML files to process" -Level Info
    
    # Process each file
    foreach ($file in $yamlFiles) {
        Repair-YamlFile -FilePath $file.FullName
    }
    
    # Summary
    Write-LogMessage "=== REPAIR SUMMARY ===" -Level Info
    Write-LogMessage "Files Processed: $script:ProcessedFiles" -Level Info
    Write-LogMessage "Files Modified: $script:ModifiedFiles" -Level Success
    Write-LogMessage "Files Backed Up: $script:BackupFiles" -Level Info
    Write-LogMessage "Files with Errors: $script:ErrorFiles" -Level $(if ($script:ErrorFiles -gt 0) { 'Warning' } else { 'Info' })
    
    if ($script:ModifiedFiles -gt 0) {
        Write-LogMessage "Backups stored in: $BackupPath" -Level Info
    }
    
    Write-LogMessage "YAML indentation repair process completed" -Level Success
}

#endregion

# Execute main function
try {
    Start-YamlRepair
}
catch {
    Write-LogMessage "Unexpected error: $($_.Exception.Message)" -Level Error
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}