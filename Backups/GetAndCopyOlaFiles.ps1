<#
.SYNOPSIS
    Get the most recent database backup for each database
.DESCRIPTION
    When using https://ola.hallengren.com/ solution, get the latest full database backup
.NOTES
    This assumes:
    - the full baxckup files have an extension ending with .bak
    - the standard Ola Hallengren solution structure is used
        . INSTANCE
           DATABASE1
            FULL
           DATABASE2
            FULL

.LINK
    https://ola.hallengren.com/
.EXAMPLE
    Get-LastOlaFullBackup -Path K:\SQLBkp
#>
function Get-LastOlaFullBackups {
    [CmdletBinding()]
    param (
        # Root Folder 
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [String]
        $Path
        
    )
    
    $Fullbackups = Get-ChildItem -Path $Path -Recurse -Filter '*.bak' -File
    $ListByFolder = $Fullbackups | Group-Object -Property Directory
    $GetFirstMostRecentInFolder = $ListByFolder | 
        ForEach-Object { $_.Group | Sort-Object -Property LastWriteTime -Descending `
                                  | Select-Object -First 1 }

    $GetFirstMostRecentInFolder # FileInfo[]

}

<#
.SYNOPSIS
    Copy the Ola backups to a target location
.DESCRIPTION
    Copy the latest full backups from User databases only 
.NOTES
    System databases are excluded by name
.LINK
    https://ola.hallengren.com/
.EXAMPLE
    Copy-OlaBackupTo -From K:\SQLBkp -To \\Server\D$\NewCopy
#>
function Copy-OlaBackupTo {
    [CmdletBinding()]
    param (
        # Root Folder 
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [String]
        $From,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [String]
        $To
    )
    $GetBackups = Get-LastOlaFullBackups -Path $From
    # change as appropriate
$GetUserDBBackups = $GetBackups | Where-Object { $_.BaseName -notmatch '_(system|master|model|msdb|oemdb)_'}
$GetUserDBBackups | Copy-Item -Destination $To -Force

}


