# YAML Indentation Repair Script

## Overview

The `Repair-YamlIndentation.ps1` script is a comprehensive PowerShell 5.1 solution designed to automatically fix YAML file indentation issues. It converts tabs to spaces, standardizes indentation levels, and preserves comments and file structure while creating backups.

## Features

- ✅ **Tab to Space Conversion**: Automatically converts tab characters to spaces
- ✅ **Standardized Indentation**: Normalizes indentation to consistent spacing (default: 2 spaces)
- ✅ **Backup System**: Creates backups maintaining original folder structure
- ✅ **Comment Preservation**: Preserves all comments and their formatting
- ✅ **YAML Validation**: Optional syntax validation before and after changes
- ✅ **Recursive Processing**: Can process entire directory trees
- ✅ **WhatIf Support**: Preview changes without modifying files
- ✅ **PowerShell Best Practices**: Uses approved verbs and proper parameter validation
- ✅ **Standalone**: No external dependencies required (optional PowerShell-Yaml module for advanced validation)

## Requirements

- PowerShell 5.1 or later
- Windows, Linux, or macOS
- Optional: PowerShell-Yaml module for advanced validation

## Installation

1. Download the script to your desired location
2. Ensure PowerShell execution policy allows script execution:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Usage

### Basic Usage

```powershell
# Repair YAML files in current directory
.\Repair-YamlIndentation.ps1

# Repair YAML files recursively
.\Repair-YamlIndentation.ps1 -Recurse

# Preview changes without modifying files
.\Repair-YamlIndentation.ps1 -WhatIf -Recurse
```

### Advanced Usage

```powershell
# Repair with custom paths and settings
.\Repair-YamlIndentation.ps1 -Path "C:\MyProject" -BackupPath "C:\Backups\yaml" -IndentSize 4 -Recurse

# Repair with validation enabled
.\Repair-YamlIndentation.ps1 -Path "." -Validate -Recurse

# Force overwrite existing backups
.\Repair-YamlIndentation.ps1 -Force -Recurse
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Path` | String | Current directory | Root path to scan for YAML files |
| `BackupPath` | String | `.\yaml-backups` | Directory where backups will be stored |
| `IndentSize` | Int | 2 | Number of spaces per indentation level (2-8) |
| `Recurse` | Switch | False | Recursively scan subdirectories |
| `WhatIf` | Switch | False | Preview changes without modifying files |
| `Force` | Switch | False | Overwrite existing backup files without prompting |
| `Validate` | Switch | False | Validate YAML syntax before and after changes |

## Examples

### Example 1: Basic Repair
```powershell
.\Repair-YamlIndentation.ps1 -Path "C:\DatadogConfigs" -Recurse
```
**Output:**
```
[2024-01-15 10:30:15] [Info] Starting YAML indentation repair process
[2024-01-15 10:30:15] [Info] Found 32 YAML files to process
[2024-01-15 10:30:16] [Success] Successfully repaired: C:\DatadogConfigs\site-server\datadog.yaml
[2024-01-15 10:30:17] [Info] No changes needed for: C:\DatadogConfigs\common\recommended-thresholds.yaml
...
[2024-01-15 10:30:25] [Info] === REPAIR SUMMARY ===
[2024-01-15 10:30:25] [Info] Files Processed: 32
[2024-01-15 10:30:25] [Success] Files Modified: 8
[2024-01-15 10:30:25] [Info] Files Backed Up: 8
[2024-01-15 10:30:25] [Info] Files with Errors: 0
```

### Example 2: Preview Mode
```powershell
.\Repair-YamlIndentation.ps1 -WhatIf -Recurse
```
Shows what would be changed without making modifications.

### Example 3: Custom Indentation
```powershell
.\Repair-YamlIndentation.ps1 -IndentSize 4 -Validate -Recurse
```
Uses 4-space indentation and validates syntax.

## Backup System

The script creates a comprehensive backup system:

```
Original Structure:          Backup Structure:
project/                     yaml-backups/
├── config/                  ├── config/
│   ├── app.yaml            │   ├── app.yaml
│   └── db.yaml             │   └── db.yaml
└── deploy/                  └── deploy/
    └── k8s.yaml                └── k8s.yaml
```

## What Gets Fixed

### Tab to Space Conversion
```yaml
# Before (with tabs)
config:
	database:
		host: localhost
		port: 5432

# After (with spaces)
config:
  database:
    host: localhost
    port: 5432
```

### Indentation Normalization
```yaml
# Before (inconsistent spacing)
config:
   database:
     host: localhost
       port: 5432

# After (consistent 2-space indentation)
config:
  database:
    host: localhost
    port: 5432
```

### Comment Preservation
```yaml
# Before and After (comments preserved)
# Database configuration
config:
  database:  # Main database
    host: localhost  # Local development
    port: 5432
```

## Error Handling

The script includes comprehensive error handling:

- **File Access Errors**: Gracefully handles locked or inaccessible files
- **Syntax Validation**: Optional pre/post validation with rollback on errors
- **Backup Failures**: Skips files if backup creation fails
- **Permission Issues**: Reports and continues with other files

## Validation

When the `-Validate` switch is used:

1. **Basic Validation**: Built-in YAML structure checking
2. **Advanced Validation**: Uses PowerShell-Yaml module if available
3. **Pre-Processing**: Validates original files before modification
4. **Post-Processing**: Validates repaired files and rolls back on errors

## Performance

- **Memory Efficient**: Processes files one at a time
- **Progress Reporting**: Real-time status updates
- **Batch Processing**: Handles large directory structures efficiently

## Troubleshooting

### Common Issues

1. **Execution Policy Error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Path Not Found**
   - Verify the source path exists
   - Use absolute paths for clarity

3. **Permission Denied**
   - Run PowerShell as Administrator
   - Check file/folder permissions

4. **Backup Directory Issues**
   - Ensure sufficient disk space
   - Verify write permissions to backup location

### Debug Mode

For detailed troubleshooting, run with verbose output:
```powershell
.\Repair-YamlIndentation.ps1 -Verbose -WhatIf
```

## Integration

### CI/CD Pipeline Integration
```yaml
# Azure DevOps Pipeline Example
- task: PowerShell@2
  displayName: 'Repair YAML Indentation'
  inputs:
    filePath: 'scripts/Repair-YamlIndentation.ps1'
    arguments: '-Path $(Build.SourcesDirectory) -Recurse -Validate'
```

### Git Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit
powershell.exe -File "scripts/Repair-YamlIndentation.ps1" -WhatIf -Recurse
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01-15 | Initial release with full functionality |

## Contributing

This script is part of the datadog-fun repository. Contributions and improvements are welcome through pull requests.

## License

This script is provided under the same license as the parent repository.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the script's built-in help: `Get-Help .\Repair-YamlIndentation.ps1 -Full`
3. Open an issue in the repository

---

**Note**: Always test the script on a small subset of files first and verify backups are created successfully before processing large directory structures.