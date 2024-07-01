<#
.SYNOPSIS
    Creates Azure AD users from a CSV file.

.DESCRIPTION
    This script imports user information from a CSV file and creates corresponding user accounts in Azure Active Directory (Azure AD) using the Microsoft Graph PowerShell module.

.PARAMETER FilePath
    The path to the CSV file containing user information (required).

.NOTES
    Must have Microsoft.Graph installed and have connected with Proper Scope
    Install-Module Microsoft.Graph
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    Be Sure to run Disconnect-MgGraph when finished
    CSV File Format:
    - The CSV file should have headers for the following columns (case-insensitive):
        - DisplayName
        - Firstname
        - Lastname
        - Email (used as UserPrincipalName)
        - Password

    Permissions:
    - The account used to run this script must have sufficient permissions in Azure AD to create users (e.g., User.ReadWrite.All).
.EXAMPLE
    New-MgUserFromCsvWithDefinedPassword -FilePath "C:\Path\to\your\csv"
#>

# Function to create Azure AD users from CSV data
function New-MgUserFromCsvWithDefinedPassword  {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Path to the CSV file containing user data")]
        [string]$FilePath
    )

    # Import users from the CSV file
    $Users = Import-Csv -Path $FilePath
    
    foreach ($User in $Users) {
        # Extract mail nickname from email address
        $MailNickName = ($User.Email -split "@")[0].Trim()

        # Create a password profile object
        $PasswordProfile = @{
            Password = $User.Password
            ForceChangePasswordNextSignIn = $false  # Optionally change to $true to force password change on first login
        }

        # Create the user in Azure AD
        New-MgUser -DisplayName $user.DisplayName -GivenName $user.Firstname -Surname $user.Lastname `
                   -UserPrincipalName $user.Email -MailNickname $mailNickName `
                   -PasswordProfile $passwordProfile -AccountEnabled $true
        
        Write-Verbose "Created user: $($user.DisplayName) ($($user.Email))"
    }
}