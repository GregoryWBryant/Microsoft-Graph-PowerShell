<#
.SYNOPSIS
    Disables sign-in for a specified user.

.DESCRIPTION
    This script prompts the user for the UPN of a user in the Azure Active Directory (Azure AD) tenant 
    and disables their sign-in.

.NOTES
      The account used to run this script must have sufficient permissions in Azure AD (e.g., Global Administrator or User Administrator).
      This will prevent the specified user from logging into Azure AD services.
#>

# Connect to Microsoft Graph using the `Connect-MgGraph` cmdlet
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Prompt the user to enter the UPN of the user to disable
$UserPrincipalName = Read-Host -Prompt "Enter the User Principal Name (UPN) of the user to disable:"

# Get the user object based on the provided UPN
$User = Get-MgUser -Filter "UserPrincipalName eq '$userPrincipalName'"

# Check if the user exists
if ($User) {
    Write-Verbose "Disabling sign-in for: $($user.DisplayName) ($($user.UserPrincipalName))"

    # Prepare the body parameter with accountEnabled set to false
    $params = @{
        AccountEnabled = $false
    }
    # Update the user's accountEnabled property using -BodyParameter
    Update-MgUser -UserId $user.Id -BodyParameter $params
} else {
    Write-Warning "No user found with the UPN '$UserPrincipalName'."
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
