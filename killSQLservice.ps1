
# Abruptly kill the processes related to SQL Server and additional tools (IBM Guardium)
function Get-PIDForService {
    param(
    # Parameter help description
    [Parameter(ParameterSetName='Specific')]
    [string]
    $Name,
    [Parameter(ParameterSetName='Like')]
    [string]
    $Like,
    [Parameter(ParameterSetName='Fuzzy')]
    [string]
    $FuzzySearch
    )
    
    switch ($PSCmdlet.ParameterSetName) {
        "Specific" {
            $filter = "name = '" + $Name + "'"
        }
        "Like" {
            $filter =  "name like '"+ $Like + "%'"
        }
        "Fuzzy" {
            $filter =  "name like '"+$FuzzySearch +"%' or DisplayName like '%" + $FuzzySearch +"%'"
        }        
    }

    $WmiServices = Get-WmiObject Win32_Service -Filter $filter
    return $WmiServices
}


    $SQLSvcs = Get-PIDForService -Like 'MSSQL$'
    $GuardiumSvcs = Get-PIDForService -FuzzySearch 'Guardium'
    Write-Verbose "${$SQLSvcs.Length} SQL Server services found."
    Write-Verbose "${$GuardiumSvcs.Length} Guardium services found."
    
    $SQLSvcs, $GuardiumSvcs | ForEach-Object {
        if ($_.Started) {
            $svcpid = $_.ProcessID 
            Write-Verbose "Service ${$_.Name} [PID: $svcpid]"
            Stop-Process -Id $SvcPid -Force
        } else {
            Write-Verbose "Service ${$_.Name} [Not Started]"
        }
    }
    
