# SCCM Datadog Monitoring Configuration Package

Comprehensive Datadog monitoring configurations for Microsoft System Center Configuration Manager (SCCM) servers using Windows Authentication for enhanced security and LCD monitoring approach.

## Prerequisites

- Active Datadog account with API key
- Windows Server 2016+ with PowerShell 5.1+
- Administrator privileges on SCCM servers
- Datadog Agent service account with SQL Server access (Windows Authentication)

## Components

- **Site Server**: Basic SCCM site server monitoring with essential services
- **Management Point**: Client communication endpoint monitoring
- **Distribution Point**: Content distribution monitoring with IIS
- **SQL Server**: Database performance monitoring with Windows Authentication
- **SQL Reporting Server**: SSRS monitoring with Windows Authentication

## Quick Start

1. Clone this repository to your deployment server
2. Update `servers.json` with your SCCM server details
3. Replace `YOUR_API_KEY_HERE` with your actual Datadog API key
4. Run the deployment script:
   ```powershell
   .\Deploy-DatadogConfigs.ps1
   ```

## Security

All SQL Server connections use Windows Authentication (`Trusted_Connection=yes`) eliminating the need for stored credentials. Ensure the Datadog Agent service account has appropriate SQL Server permissions.

## Repository Structure

```
├── site-server/           # Primary site server configs
├── management-point/      # Management point configs  
├── distribution-point/    # Distribution point configs
├── sql-server/           # SQL database server configs
├── sql-reporting-server/ # SQL reporting server configs
├── dashboards/           # Datadog dashboard templates
├── common/              # Shared configuration files
└── Deploy-DatadogConfigs.ps1  # Automated deployment script
```

## Documentation

- [Project_Details.md](Project_Details.md) - Comprehensive project information and setup guide
- [Project_Components.md](Project_Components.md) - Detailed component descriptions and structure

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions, please create an issue in this repository or contact your Datadog support team.
