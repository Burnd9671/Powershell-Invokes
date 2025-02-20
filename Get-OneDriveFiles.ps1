<#
    .SYNOPSIS
    Get-OneDriveFiles.ps1

    .DESCRIPTION
    The script imports users from a specified CSV file and downloads all
    OneDrive files for each user to a specified local folder.

    .LINK
    www.alitajran.com/download-all-user-onedrive-files/

    .NOTES
    Written by: ALI TAJRAN
    Website:    www.alitajran.com
    LinkedIn:   linkedin.com/in/alitajran

    .CHANGELOG
    V1.00, 11/22/2024 - Initial version
#>

# Parameters for CSV file input and export directory
param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    [Parameter(Mandatory = $true)]
    [string]$ExportPath
)

# Connect to Microsoft Graph with necessary permissions
Connect-MgGraph -Scopes "Directory.Read.All", "Sites.Read.All", "Files.Read.All" -NoWelcome

# Import users from CSV file
$users = Import-Csv -Path $CsvPath

# Local folder path for OneDrive files export
$Folder = $ExportPath

function Get-DriveItems {
    param (
        [string]$DriveId,
        [string]$DriveItemId,
        [string]$LocalPath
    )

    # Ensure the local path exists
    New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null

    # Fetch children of the current drive item
    $driveItemChildren = Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $DriveItemId

    foreach ($item in $driveItemChildren) {
        if ($item.File.MimeType) {
            # It's a file
            $fileName = $item.Name
            $filePath = Join-Path -Path $LocalPath -ChildPath $fileName
            # Download the file
            Get-MgDriveItemContent -DriveId $DriveId -DriveItemId $item.id -OutFile $filePath
            Write-Host "Downloaded file: $filePath" -ForegroundColor Green
        }
        elseif ($item.Folder) {
            # It's a folder
            $newLocalPath = Join-Path -Path $LocalPath -ChildPath $item.Name
            Write-Host "Entering folder: $newLocalPath" -ForegroundColor Cyan
            Get-DriveItems -DriveId $DriveId -DriveItemId $item.id -LocalPath $newLocalPath
        }
    }
}

foreach ($user in $users) {
    $userPrincipalName = $user.UserPrincipalName

    # Fetch user information
    $userObject = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'"
    if (-not $userObject) {
        Write-Host "User not found: $($userPrincipalName)" -ForegroundColor Yellow
        continue
    }

    # Fetch user's OneDrive drives
    $userOneDrive = Get-MgUserDefaultDrive -UserId $userObject.id -ErrorAction SilentlyContinue
    if ($userOneDrive) {
        $driveId = $userOneDrive.id

        # Create a directory for the user's data
        $userDirectory = "$Folder\$userPrincipalName"
        New-Item -ItemType Directory -Path $userDirectory -Force | Out-Null

        # Start downloading from the root
        Get-DriveItems -DriveId $driveId -DriveItemId "root" -LocalPath $userDirectory
    }
    else {
        Write-Host "Error accessing OneDrive for user: $($userPrincipalName). Skipping." -ForegroundColor Red
    }
}

# Final message to indicate completion
Write-Host "All operations completed successfully. Files exported to $ExportPath." -ForegroundColor Cyan