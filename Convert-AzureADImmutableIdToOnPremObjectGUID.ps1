<#
.SYNOPSIS
    Converts Azure AD Immutable ID to on-premises AD Object GUID.

.DESCRIPTION
    This script contains functions to:
        Convert-ImmutableIDToObjectGUID: Converts a Base64-encoded Immutable ID to a GUID string.
        Get-UserImmutableId: Retrieves the Immutable ID of a user by UPN from Azure AD.
        Get-UserADObjectID: Combines the above functions to directly get the on-premises Object GUID for a user.
        The GUID can then be used to find the exact acconut in AD the Azure object is syncing to for Troubleshooting.

.PARAMETER UserPrincipalName (for Get-User* functions)
    The UPN of the user to look up.

.NOTES
      Ensure the executing account has User.Read.All in Microsoft Graph.
      Immutable ID is only relevant for users synced from on-premises AD.

.EXAMPLE
    # Get GUID directly:
    Get-UserADObjectID -UserPrincipalName "john.doe@example.com"

    # Manual steps:
    $immutable = Get-UserImmutableId -UserPrincipalName "john.doe@example.com"
    $guid = Convert-ImmutableIDToObjectGUID -ImmutableID $immutable
#>

# --- Function: Convert-ImmutableIDToObjectGUID ---
function Convert-ImmutableIDToObjectGUID {
    param (
        [Parameter(Mandatory)]
        [string]$ImmutableID
    )
    
    # Base64 decode, then reverse byte order (as Azure AD stores it differently)
    $bytes = [System.Convert]::FromBase64String($ImmutableID)
    [Array]::Reverse($bytes)

    # Create a GUID object from the reversed bytes, format for output
    return [System.Guid]::new($bytes).ToString("D")
}

# --- Function: Get-UserImmutableId ---
function Get-UserImmutableId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )

    # Connect to Microsoft Graph only when needed
    Connect-MgGraph -Scopes "User.Read.All"

    try {
        # Retrieve user, explicitly requesting OnPremisesImmutableId
        $user = Get-MgUser -Filter "UserPrincipalName eq '$UserPrincipalName'" -Property "OnPremisesImmutableId"
        return $user.OnPremisesImmutableId  # Return value directly
    } finally {
        Disconnect-MgGraph  # Always disconnect, even if an error occurs
    }
}

# --- Function: Get-UserADObjectID ---
function Get-UserADObjectID {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$UserPrincipalName
    )

    $immutableID = Get-UserImmutableId -UserPrincipalName $UserPrincipalName

    if ($immutableID) {
        return Convert-ImmutableIDToObjectGUID -ImmutableID $immutableID
    } else {
        Write-Warning "No Immutable ID found for user '$UserPrincipalName'."
        return $null  # Explicitly return null if no ID found
    }
}
