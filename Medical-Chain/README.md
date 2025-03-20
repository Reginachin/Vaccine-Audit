# Vaccine Tracking Smart Contract

## Overview
This smart contract implements a comprehensive vaccine tracking system built on blockchain technology. It enables healthcare providers to manage vaccine inventory, track patient vaccinations, monitor storage conditions, and maintain regulatory compliance throughout the vaccine supply chain.

## Features
- **Inventory Management**: Track vaccine batches from production to administration
- **Patient Records**: Maintain secure vaccination histories with privacy protections
- **Provider Authorization**: Verify healthcare providers' credentials and permissions
- **Storage Monitoring**: Log temperature data and breach incidents
- **Dose Tracking**: Manage vaccination schedules and follow-up appointments

## Data Structures

### Vaccine Inventory
Tracks detailed information about each vaccine batch:
- Manufacturer and product information
- Production and expiration dates
- Dose quantities
- Storage requirements
- Current status
- Temperature breach incidents
- Storage location

### Patient Records
Securely stores patient vaccination data:
- Vaccination history with batch IDs
- Injection dates and locations
- Total doses received
- Adverse reaction reports
- Medical exemption details

### Provider Authorization
Validates healthcare providers' access rights:
- Staff role and facility information
- Credential expiration dates

### Storage Facilities
Monitors vaccine storage conditions:
- Physical location information
- Storage capacity and current stock
- Temperature logs

## Key Functions

### Administration
- `transfer-admin-rights`: Transfer contract administrative privileges
- `add-healthcare-provider`: Register authorized healthcare providers
- `add-storage-location`: Add new storage facilities

### Vaccine Management
- `add-vaccine-batch`: Register new vaccine inventory
- `update-batch-status`: Modify batch status (active, expired, recalled)
- `log-temperature-breach`: Record temperature excursions

### Patient Functions
- `register-vaccination`: Record patient vaccination events
- `get-patient-history`: Retrieve patient vaccination records

### Reporting Functions
- `get-batch-details`: Retrieve vaccine batch information
- `get-facility-details`: Access storage facility data
- `is-batch-valid`: Verify batch integrity and usability

## Error Handling
The contract includes comprehensive error codes for validation failures, unauthorized access attempts, and data integrity issues.

## Safety Features
- Temperature range validation
- Expiration date checks
- Dose interval enforcement
- Maximum dose limits
- Batch quality monitoring

## Usage Requirements
- Clarity-compatible blockchain environment
- Authorized provider credentials
- Valid patient and batch identifiers

## Security Considerations
- All write operations require valid provider credentials
- Administrative functions restricted to contract administrator
- Data validation for all inputs
- Privacy protections for patient information

## Limitations
- Maximum 10 vaccination events per patient record
- Maximum 5 adverse reaction reports per patient
- Maximum 100 temperature log entries per facility
- Minimum 21-day interval between doses
- Maximum 4 doses per patient