<#
    Script to update user licenses in bulk using Microsoft Graph PowerShell.

    Requirements:
        Microsoft Graph PowerShell module (Install-Module Microsoft.Graph)
        Azure AD administrative permissions (User.ReadWrite.All, Organization.Read.All)
        CSV file with columns: Email, Remove (comma-separated list of licenses to remove), Add (comma-separated list of licenses to add)

    Note
        The script gets a list of your tenant's available licenses to ensure accurate license assignment.
        The "Remove" and "Add" columns in the CSV can be left blank if no action is needed for that user.
        Ensure license names in the CSV match the keys in the $SkuIds hashtable.
#>


# Connect to Microsoft Graph with Required Scopes
Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All"

# License SKU Mapping (Human-readable name to SkuPartNumber)
$SkuIds = @{
    "Azure Active Directory Premium P1" = "AAD_PREMIUM";
    "Azure Information Protection Premium P1" = "RIGHTSMANAGEMENT_CE";
    "Office 365 F3" = "DESKLESSPACK";
    "Office 365 E1" = "STANDARDPACK";
    "Office 365 E3" = "ENTERPRISEPACK";
    "Office 365 E5" = "ENTERPRISEPREMIUM";
    "Exchange Online (Plan 1)" = "EXCHANGESTANDARD";
    "Exchange Online Kiosk" = "EXCHANGEDESKLESS";
    "Microsoft 365 Business Basic" = "O365_BUSINESS_ESSENTIALS";
    "Microsoft 365 Business Standard" = "O365_BUSINESS_PREMIUM";
    "Microsoft 365 Business Premium" = "SPB";
    "Microsoft 365 Apps for Business" = "O365_BUSINESS"; 
    "Microsoft 365 Apps for Enterprise" = "OFFICESUBSCRIPTION"
}

# Get Available Licenses for Your Tenant
$AvailableSkus = Get-MgSubscribedSku -All

# Import Users from CSV
$Users = Import-Csv -Path "C:\path\to\your\csv"


# Process Each User
foreach ($User in $Users) {
    Write-Host ("Updating: " + $User.Email)
    Update-MgUser -UserId $User.Email -UsageLocation "US"  # Update usage location (if needed)
    $RemoveLicense = @()  # Reset the list of licenses to remove for each user

    # Remove Licenses (if specified)
    if ($LicensestoRemove -ne "") {
        $LicensesToRemove = $User.Remove -split ","
        foreach ($LicenseToRemove in $LicensesToRemove) {
            $skuPartNumberToRemove = $SkuIds[$LicenseToRemove.Trim()]
            if ($skuPartNumberToRemove) {
                $RemoveLicense += ($AvailableSkus | Where-Object { $_.SkuPartNumber -eq $skuPartNumberToRemove }).SkuId
            } else {
                Write-Warning "License to remove not found: $LicenseToRemove"
            }
        }

        Set-MgUserLicense -UserId $User.Email -RemoveLicenses $RemoveLicense -AddLicenses @{}
    }

    # Add Licenses (if specified)
    if ($LicensestoAdd -ne "") {
        $LicensesToAdd = $User.Add -split ","
        foreach ($LicenseToAdd in $LicensesToAdd) {
            $skuPartNumberToAdd = $SkuIds[$LicenseToAdd.Trim()]
            if ($skuPartNumberToAdd) {
                $addLicense = ($AvailableSkus | Where-Object { $_.SkuPartNumber -eq $skuPartNumberToAdd }).SkuId
                Set-MgUserLicense -UserId $User.Email -AddLicenses @{ SkuId = $addLicense } -RemoveLicenses @{}
            } else {
                Write-Warning "License to add not found: $LicenseToAdd"
            }
        }
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
