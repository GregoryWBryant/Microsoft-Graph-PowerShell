<#
.SYNOPSIS
    Creates Azure AD users from a CSV file with generated passwords.

.DESCRIPTION
    This script imports user information from a CSV file and creates corresponding user accounts in Azure Active Directory (Azure AD) using the Microsoft Graph PowerShell module.
    It generates random passwords for each user based on a predefined pattern.

.PARAMETER FilePath
    The path to the CSV file containing user information (required).

.NOTES
    Must have Microsoft.Graph installed and have connected with Proper Scope
    Install-Module Microsoft.Graph
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    Be Sure to run Disconnect-MgGraph when finished
    CSV File Format:
    - The CSV file should have headers for the following columns (case-insensitive):
        - Name (DisplayName)
        - Firstname
        - Lastname
        - UPN
        - SamAccount (MailNickname)

    Permissions:
    - The user running this script must be connected to Microsoft Graph with the appropriate permissions (User.ReadWrite.All).

.EXAMPLE
    New-MgUserFromCsvWithPassword -FilePath "C:\Path\to\your\csv"
#>

function SemiRandomPassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The base word to use in the password. Defaults to 'PickStorng'.")]
        [string]$Base = "PickStorng"
    )

    # Defines Sets
    $Symbols = "$", "@", "#", "&"
    $Numbers = "0".."9"
    $Uppers = [char[]]("A"[0].."Z"[0])
    $Lowers = [char[]]("a"[0].."z"[0])

    # Get random characters from each set
    $First = Get-Random -InputObject $Symbols
    $Second = Get-Random -InputObject $Uppers
    $Third = Get-Random -InputObject $Numbers
    $Fourth = Get-Random -InputObject $Lowers

    # Combine the base word with the random characters and return the password
    return ($Base + $First + $Second +  $Third + $Fourth)
}

function New-MgUserFromCsvWithRandomPassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Path to the CSV file containing user data")]
        [string]$FilePath
    )

    $Users = Import-Csv -Path $FilePath

    foreach ($User in $Users) {
        $Password = SemiRandomPassword -Base "StartOfPassword"
        Write-Verbose "Creating user $($User.Name) with password $Password" # Added Verbose logging 
        $PasswordProfile = @{
            Password = $Password
            ForceChangePasswordNextSignIn = $false  # Optionally change to $true to force password change on first login
        }
        
        # Create the user in Azure AD using the Graph API 
        New-MgUser -DisplayName $User.Name -GivenName $User.FirstName -Surname $User.LastName `
                   -UserPrincipalName $User.UPN -MailNickname $User.SamAccount `
                   -PasswordProfile $PasswordProfile -AccountEnabled $true
        
        Write-Verbose "Created user: $($User.Name) ($($User.UPN))" # Added Verbose logging for success

    }
}
