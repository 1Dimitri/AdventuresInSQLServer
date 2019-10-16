<#
.SYNOPSIS
    Retrieves data for a DMA JSON output as a flat array
.DESCRIPTION
    From a SQL Migration Data Assistant JSON File, retrieve one line by remark
.EXAMPLE
    Get-DMAJSONResults -JSONFile .\MyDMAAssessment.JSON
.INPUTS
    -JSONFile: Json file created by SQL DMA
.OUTPUTS
    Array of PSCustomObject
.NOTES
    Based on DMA Processor 5.0 code
#>
function Get-DMAJsonResults {
    [CmdLetBinding()]
    param (
        [string]
        $JsonFile
    )
    
    $blankAssessmentRecommendations =   (New-Object PSObject |
    Add-Member -PassThru NoteProperty CompatibilityLevel NA |
    Add-Member -PassThru NoteProperty Category NA          |
    Add-Member -PassThru NoteProperty Severity NA     |
    Add-Member -PassThru NoteProperty ChangeCategory NA |
    Add-Member -PassThru NoteProperty RuleId NA |
    Add-Member -PassThru NoteProperty Title NA |
    Add-Member -PassThru NoteProperty Impact NA |
    Add-Member -PassThru NoteProperty Recommendation NA |
    Add-Member -PassThru NoteProperty MoreInfo NA |
    Add-Member -PassThru NoteProperty ImpactedObjects NA
 ) 

$blankImpactedObjects = (New-Object PSObject |
    Add-Member -PassThru NoteProperty Name NA |
    Add-Member -PassThru NoteProperty ObjectType NA          |
    Add-Member -PassThru NoteProperty ImpactDetail NA     
 )

    $content = Get-Content $JsonFile -Raw

    foreach ($obj in (ConvertFrom-Json $content)) { #level 1, the actual file          
        foreach ($database in $obj.Databases) { #level 2, the sources
            $database.AssessmentRecommendations = if ($database.AssessmentRecommendations.Length -eq 0) { $blankAssessmentRecommendations } else { $database.AssessmentRecommendations }
        
            foreach ($assessment in $database.AssessmentRecommendations) { #level 3, the assessment
            
                $assessment.ImpactedObjects = if ($assessment.ImpactedObjects.Length -eq 0) { $blankImpactedObjects } else { $assessment.ImpactedObjects }

                foreach ($impactedobj in $assessment.ImpactedObjects) { #level 4, the impacted objects
                                                            
                    [PSCUstomObject] @{
                        target_SQLVersion = $obj.TargetPlatform
                        instance=$database.ServerName
                        database_compatibility_level=$database.CompatibilityLevel -replace '^CompatLevel',''
                        instance_edition=$database.ServerEdition
                        instance_version=$database.ServerVersion
                        database=$database.Name
                        rule_compatibility_level = $assessment.CompatibilityLevel -replace '^CompatLevel',''
                        rule_category=$assessment.Category
                        rule_level=$assessment.Severity
                        rule_change=$assessment.ChangeCategory
                        rule_id=($assessment.RuleId -split '\.') | Select-Object -Last 1
                        rule_title = $assessment.Title
                        rule_explain = $assessment.Impact
                        rule_remediation = $assessment.Recommendation
                        rule_additionalinfo = $assessment.MoreInfo                        
                        target_object_type=$impactedobj.ObjectType
                        target_object_name=$impactedobj.Name
                        target_object_explain = $impactedobj.ImpactDetail

                    }
                }
            }
        }
    }   
    
}

function Get-DMAHTMLReports {
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $JsonFile,

        [string]
        $logo,

        [string]
        $cssfile
        
    )
    
     $JsonBaseName = (Get-Item $JsonFile).BaseName

    $rules = Get-DMAJsonResults -JsonFile $JsonFile

    $versions = (($rules | Select-Object -Unique -ExpandProperty target_SQLVersion) -join ', ') -replace 'SqlServer','SQL Server '
    $gd = (Get-Date).ToString('dd/MM/yyyy HH:mm')
    $footer = "<br /> Generated at $gd"
    $cnvparams = @{ PostContent=$footer}
    if ($cssfile) {
        $cnvparams['CssUri']=$cssfile
    }
    if ($logo) {
        $header='<img src="'+$logo+'" alt="logo"><br /><br /><h1>Migration towards '+$versions+'</h1><br /><br>'
    } else {
        $header='<h1>Migration towards '+$versions+'</h1><br /><br>'
    }


    $dbs_only = $rules | Select-Object -Unique -Property Database, instance, instance_version, instance_edition, database_compatibility_level
    $dbs_only_report = $dbs_only | ConvertTo-Html -Title 'Affected databases' -PreContent "$header The following instances and databases are concerned:" @cnvparams
    $dbs_only_report | Set-Content ($JsonBaseName+"-Affected-Databases.html") -Force

    $rules_only = $rules | Select-Object -Unique -Property rule_category, rule_level, rule_change, rule_title, rule_explain
    $rules_only_report = $rules_only | ConvertTo-Html -Title 'Issues and recommendations' -PreContent "$header The following issues and recommendations were found:" @cnvparams
    $rules_only_report | Set-Content ($JsonBaseName+"-Rules.html") -Force

    $details_only = $rules | Select-Object -Unique -Property target_object_type, target_object_name, rule_title, target_object_explain, rule_remediation 
    $details_only_report = $details_only | ConvertTo-Html -Title 'Affected database objects' -PreContent "$header The following database objects (procedures, tables, views, etc.) are concerned:" @cnvparams  
    $details_only_report | Set-Content ($JsonBaseName+"-Details-By-Object.html") -Force

    
}
