param(
    [string]$Path = ".",
    [switch]$Apply = $false,
    [switch]$AutoInstallModule = $false
)

function Write-Log { param($m,$l="INFO"); $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; Write-Host "[$t] [$l] $m" }

# Ensure module 'powershell-yaml' is available with correct version
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    if ($AutoInstallModule) {
        Write-Log "Installing module 'powershell-yaml' (CurrentUser scope)..." "INFO"
        try {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop -MinimumVersion "0.4.2"
        }
        catch {
            Write-Log "Failed to install 'powershell-yaml': $($_.Exception.Message)" "ERROR"
            exit 2
        }
    }
    else {
        Write-Log "Module 'powershell-yaml' not found. Re-run with -AutoInstallModule to install automatically." "ERROR"
        exit 2
    }
}

Import-Module powershell-yaml -ErrorAction Stop -MinimumVersion "0.4.2"

# Resolve path
$root = Resolve-Path -Path $Path

Write-Log "Scanning for .yml/.yaml under $root" "INFO"
$files = Get-ChildItem -Path $root -Recurse -Include *.yml,*.yaml -File -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Log "No YAML files found." "INFO"
    exit 0
}

$wouldChange = @()
$changed = @()

foreach ($f in $files) {
    Write-Log "Processing: $($f.FullName)" "INFO"
    try {
        $orig = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction Stop
        
        # Try to parse YAML
        $yamlObject = ConvertFrom-Yaml -Yaml $orig -ErrorAction Stop
        
        # Convert back to YAML with proper indentation
        # Using StringBuilder for better performance
        $sb = [System.Text.StringBuilder]::new()
        $writer = [System.IO.StringWriter]::new($sb)
        $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
        
        # Create serializer with indent options
        $serializer = New-Object YamlDotNet.Serialization.SerializerBuilder
        $serializer = $serializer.WithIndentedSequences()
        $serializer = $serializer.Build()
        
        # Serialize with proper indentation
        $formatted = $serializer.Serialize($yamlObject)
        
        # Normalize line endings and trim trailing whitespace
        $normOrig = ($orig -replace "`r`n","`n").TrimEnd()
        $normFormatted = ($formatted -replace "`r`n","`n").TrimEnd()

        if ($normOrig -ne $normFormatted) {
            $wouldChange += $f.FullName
            if ($Apply) {
                try {
                    $bak = "$($f.FullName).bak.$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
                    Copy-Item -Path $f.FullName -Destination $bak -Force
                    # Write with UTF8 (no BOM)
                    [System.IO.File]::WriteAllText($f.FullName, $formatted, [System.Text.Encoding]::UTF8)
                    Write-Log "Updated: $($f.FullName) (backup: $bak)" "SUCCESS"
                    $changed += $f.FullName
                }
                catch {
                    Write-Log "Failed to write file $($f.FullName): $($_.Exception.Message)" "ERROR"
                    continue
                }
            }
            else {
                Write-Log "Would modify: $($f.FullName) (run with -Apply to overwrite)" "WARNING"
            }
        }
        else {
            Write-Log "No change needed: $($f.FullName)" "INFO"
        }
    }
    catch {
        Write-Log "Error processing $($f.FullName): $($_.Exception.Message)" "ERROR"
        continue
    }
}

Write-Log "Summary: Found $($files.Count) YAML files. Would change: $($wouldChange.Count). Applied: $($changed.Count)" "INFO"
if (-not $Apply -and $wouldChange.Count -gt 0) {
    Write-Host ""
    Write-Host "Files that would be changed:"
    $wouldChange | ForEach-Object { Write-Host " - $_" }
}

Write-Log "Completed YAML indentation check/fix" "SUCCESS"
exit 0
