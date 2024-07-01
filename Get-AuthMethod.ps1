<#
.SYNOPSIS
    Audits Azure AD users' multi-factor authentication (MFA) and licensing details.

.DESCRIPTION
    This script retrieves information about all active Azure AD users, including their MFA methods, licensing status, and last sign-in activity. It exports the results to a CSV file for further analysis.

.OUTPUTS
    C:\Temp\MFAAudit.csv: A CSV file containing user authentication and licensing details.

.NOTES
    Microsoft Graph PowerShell Module: Make sure you have the Microsoft Graph PowerShell module installed 
        Install-Module Microsoft.Graph
    An Entra ID P1 (Formerly Azure AD Premium P1) or P2 is required by at least one user in the Tenant for this script to work.

    Column Descriptions in MFAAudit.csv:
          DisplayName: User's display name.
          JobTitle: User's job title.
          Department: User's department.
          Location: User's office location.
          userPrincipalName: User's email address (UPN).
          id: User's object ID.
          License: Comma-separated list of assigned license SKUs.
          Licensed: Indicates if the user has any licenses ("Yes" or "No").
          MFARegistered: Indicates if the user has more than one authentication method registered ("Yes" or "No").
          Phone, MicrosoftAuthenticator, ThirdPartyAuthenticator, Email, HelloForBusiness, fido2, Password, Passwordless: Indicates whether the respective authentication method is enabled for the user ("Yes" or "No").
          Created: User's creation date and time.
          LastInterActiveSignin: User's last interactive sign-in date and time.
          LastNonInteractiveSignin: User's last non-interactive sign-in date and time.
          UserType: User type (e.g., "Member").
#>

#Connect to Microsoft Graph
Connect-MgGraph -Scopes 'User.Read.All','UserAuthenticationMethod.Read.All','Directory.Read.All','AuditLog.Read.All','Organization.Read.All'

$AllUsers = Get-mguser -Filter 'accountEnabled eq true' -All -Property SignInActivity
$AuthInfo = [System.Collections.ArrayList]::new()

ForEach ($User in $AllUsers){
    $UserAuthMethod = $null
    $UserAuthMethod = Get-MgUserAuthenticationMethod -UserId "$($User.id)"
    $object = [PSCustomObject]@{
        DisplayName               = $User.Displayname
        JobTitle                  = $User.JobTitle
        Department                = $User.Department
        Location                  = $User.OfficeLocation
        userPrincipalName         = $User.userPrincipalName
        id                        = $User.id
        License                   = (Get-MgUserLicenseDetail -UserId $User.Id).SkuPartNumber -join ", "
        Licensed                  = If (($User.AssignedLicenses).Count -ne 0) {"Yes"} Else {"No"}
        MFARegistered             = If (($UserAuthMethod).count -gt 1) {"Yes"} Else {"No"}
        Phone                     = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.phoneAuthenticationMethod") {"Yes"} Else {"No"}
        MicrosoftAuthenticator    = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod") {"Yes"} Else {"No"}
        ThirdPartyAuthenticator   = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.softwareOathAuthenticationMethod") {"Yes"} Else {"No"}
        Email                     = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.emailAuthenticationMethod") {"Yes"} Else {"No"}
        HelloForBusiness          = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod") {"Yes"} Else {"No"}
        fido2                     = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.fido2AuthenticationMethod") {"Yes"} Else {"No"}
        Password                  = If ($UserAuthMethod.additionalproperties.values  -match "#microsoft.graph.passwordAuthenticationMethod") {"Yes"} Else {"No"}
        Passwordless              = If ($UserAuthMethod.additionalproperties.values -match "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod") {"Yes"} Else {"No"}
        Created                   = $User.CreatedDateTime
        LastInterActiveSignin     = ($User.SignInActivity).LastSignInDateTime
        LastNonInteractiveSignin  = ($User.SignInActivity).lastNonInteractiveSignInDateTime
        UserType                  = $User.UserType
    }
    [void]$AuthInfo.Add($object)
}

$AuthInfo | Export-csv "C:\Path\To\Export\csv" -NoTypeInformation

Disconnect-MgGraph