<#
.SYNOPSIS
    Updates Immutable IDs for Azure AD users from a CSV file.

.DESCRIPTION
    This script imports a CSV file containing user email addresses and Immutable IDs. It then attempts to find each user in Azure AD using their email address. If the user is found, the script will update their Immutable ID. 

.PARAMETER FilePath
    The path to the CSV file containing user information (required).

.NOTES
    The CSV file should have headers (case-insensitive) for the following columns:
        EmailAddress (The user's email address)
        ImmutableID (The new Immutable ID to assign to the user)

    Immutable ID Considerations:
          Immutable IDs are used for synchronization between on-premises Active Directory and Azure AD.
          Changing Immutable IDs can have significant implications for synchronization and user management.
          Proceed with caution and ensure you understand the consequences before modifying Immutable IDs.**

#>

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'

#Import the CSV file
$Users = Import-Csv -Path "C:\Path\To\Your\csv"

# Iterate through each user in the CSV
foreach ($User in $Users) {

    $UserEmail = $User.EmailAddress

    try {
        # Try to find the user in Azure AD by email address
        $EntraUser = Get-MgUser -Filter "userPrincipalName eq '$userEmail'" -Property "OnPremisesImmutableId"
        $Exist = $true 
    } catch {
        # If the user is not found, write an error message
        Write-Error "User not found with email: $userEmail"
        $Exist = $false
    }

    # If the user was found, update their Immutable ID
    If ($Exist) {
          Write-Output ("Setting Immutabele ID for: " + $EntraUser.DisplayName)
          Write-Output ("Old Immutable ID: " + $EntraUser.OnPremisesImmutableId)
          Write-Output ("New Immutable ID: " + $User.ImmutableID)
          Update-MgUser -UserId $EntraUser.Id -OnPremisesImmutableId $User.ImmutableID
    } else {
        # If the user was not found, write an output message
        Write-Output "User does not Exist"
    }
}