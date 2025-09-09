[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = ".",
    [switch]$Apply
)

function Write-Log { 
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Format-YamlPreservingComments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [switch]$Apply
    )

    try {
        # Read file content and split into lines
        $content = Get-Content -Path $FilePath -Raw
        $lines = $content -split "`r?`n"
        
        # Create structure to store comments and content
        $documentStructure = @()
        $yamlContent = @()
        
        # First pass - separate comments and YAML content
        foreach ($line in $lines) {
            if ($line -match '^\s*#') {
                # Store comment with its indentation
                $indent = ($line | Select-String '^\s*').Matches[0].Value
                $documentStructure += @{
                    Type = 'Comment'
                    Content = $line
                    Indent = $indent.Length
                }
            }
            elseif ([string]::IsNullOrWhiteSpace($line)) {
                $documentStructure += @{
                    Type = 'Empty'
                    Content = ''
                }
            }
            else {
                # Store YAML content for processing
                $documentStructure += @{
                    Type = 'YAML'
                    Content = $line
                    OriginalIndent = ($line | Select-String '^\s*').Matches[0].Value.Length
                }
                $yamlContent += $line
            }
        }

        # Process YAML content
        $yaml = $yamlContent | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Out-String
        $parsedYaml = ConvertFrom-Yaml -Yaml $yaml
        $formattedYaml = ConvertTo-Yaml -Data $parsedYaml
        $formattedLines = $formattedYaml -split "`r?`n"
        
        # Rebuild document preserving comments
        $result = New-Object System.Collections.ArrayList
        $yamlIndex = 0
        
        foreach ($item in $documentStructure) {
            switch ($item.Type) {
                'Comment' {
                    $result.Add($item.Content) | Out-Null
                }
                'Empty' {
                    $result.Add('') | Out-Null
                }
                'YAML' {
                    if ($yamlIndex -lt $formattedLines.Count) {
                        $formattedLine = $formattedLines[$yamlIndex]
                        if (-not [string]::IsNullOrWhiteSpace($formattedLine)) {
                            $result.Add($formattedLine) | Out-Null
                            $yamlIndex++
                        }
                    }
                }
            }
        }

        $newContent = $result -join "`n"

        # Only apply changes if content has actually changed
        if ($newContent -ne $content) {
            if ($Apply) {
                $backupPath = "$FilePath.bak.$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
                Copy-Item -Path $FilePath -Destination $backupPath -Force
                Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
                Write-Log "Updated and backed up: $([System.IO.Path]::GetFileName($FilePath))" -Level "SUCCESS"
                return $true
            }
            else {
                Write-Log "Would modify: $([System.IO.Path]::GetFileName($FilePath))" -Level "WARNING"
                return $true
            }
        }
        
        Write-Log "No changes needed: $([System.IO.Path]::GetFileName($FilePath))" -Level "INFO"
        return $false
    }
    catch {
        Write-Log "Error processing $([System.IO.Path]::GetFileName($FilePath)): $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Main execution
try {
    # Ensure powershell-yaml module is available
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Log "Installing powershell-yaml module..." -Level "INFO"
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
    }
    Import-Module powershell-yaml -ErrorAction Stop

    $yamlFiles = Get-ChildItem -Path $Path -Recurse -Include *.yml,*.yaml -File
    $changedFiles = 0
    $totalFiles = $yamlFiles.Count

    Write-Log "Found $totalFiles YAML files to process" -Level "INFO"
    
    foreach ($file in $yamlFiles) {
        if (Format-YamlPreservingComments -FilePath $file.FullName -Apply:$Apply) {
            $changedFiles++
        }
    }

    Write-Log "`nSummary:" -Level "INFO"
    Write-Log "Total files processed: $totalFiles" -Level "INFO"
    Write-Log "Files modified: $changedFiles" -Level "SUCCESS"
}
catch {
    Write-Log "Script error: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}
