param(
    [string] $ResourceGroupName,
    [string] $DeploymentName = ""
)
$ErrorActionPreference = "Stop"

<#
 # Helper function for other cmdlets
 #>
function ParseOperationDuration($durationString) {

    # expected behaviour (should put in tests)
    #(ParseOperationDuration "PT21.501S").ToString() # Timespan: 21.501 seconds
    #(ParseOperationDuration "PT5M21.501S").ToString() # Timespan: 5 minutes 21.501 seconds
    #(ParseOperationDuration "PT1H5M21.501S").ToString() # Timespan: 1 hour 5 minutes 21.501 seconds
    #(ParseOperationDuration "PT 21.501S").ToString() # throws exception for unhandled format

    $timespan = $null
    switch -Regex ($durationString) {
        "^PT(?<seconds>\d*.\d*)S$" {
            $timespan = New-TimeSpan -Seconds $matches["seconds"]
        }
        "^PT(?<minutes>\d*)M(?<seconds>\d*.\d*)S$" {
            $timespan = New-TimeSpan -Minutes $matches["minutes"] -Seconds $matches["seconds"]
        }
        "^PT(?<hours>\d*)H(?<minutes>\d*)M(?<seconds>\d*.\d*)S$" {
            $timespan = New-TimeSpan -Hours $matches["hours"] -Minutes $matches["minutes"] -Seconds $matches["seconds"]
        }
    }
    if ($null -eq $timespan) {
        $message = "unhandled duration format '$durationString'"
        throw $message
    }
    $timespan
}

function GetOperations($deployment) {
    Get-AzureRmResourceGroupDeploymentOperation `
        -ResourceGroupName $ResourceGroupName `
        -DeploymentName $deployment.DeploymentName `
        | ForEach-Object {
        $timeStamp = [System.DateTime]::Parse($_.Properties.Timestamp);
        $duration = (ParseOperationDuration $_.Properties.Duration);
        [PSCustomObject]@{ 
            "Id"                = $_.OperationId; 
            "ProvisioningState" = $_.Properties.ProvisioningState; 
            "ResourceType"      = $_.Properties.TargetResource.ResourceType; 
            "ResourceName"      = $_.Properties.TargetResource.ResourceName; 
            "StartTime"         = $timeStamp - $duration; 
            "EndTime"           = $timeStamp; 
            "Duration"          = $duration;
            "Error"             = $_.Properties.StatusMessage.Error;
        }
    } `
        | Sort-Object -Property StartTime, ResourceType, ResourceName, Id
}
function DumpOperations($operations) {
    # $tableFormat = @{Expression = {$_.Id}; Label = "ID"}, `
    # @{Expression = {$_.ProvisioningState}; Label = "State"; width = 15}, `
    # @{Expression = {$_.ResourceType}; Label = "ResourceType"; width = 15}, `
    # @{Expression = {$_.ResourceName}; Label = "ResourceName"; width = 15}, `
    # @{Expression = {$_.StartTime}; Label = "StartTime"; width = 40}
    $tableFormat = @{Expression = {$_.ProvisioningState}; Label = "State"; width = 12}, `
    @{Expression = {$_.ResourceType}; Label = "ResourceType"; width = 45}, `
    @{Expression = {$_.ResourceName}; Label = "ResourceName"; width = 45}, `
    @{Expression = {$_.StartTime}; Label = "StartTime"; width = 20}, `
    @{Expression = {$_.Duration}; Label = "Duration"; width = 20}

    $text = $operations | Format-Table  $tableFormat | Out-String
    $text.Split("`r") | ForEach-Object {
        $line = $_.Trim("`n")
        if ($line.StartsWith("Succeeded")){
            Write-Host -ForegroundColor DarkGray $line
        } elseif ($line.StartsWith("Running")){
            Write-Host -ForegroundColor Green $line
        } elseif ($line.StartsWith("Failed")){
            Write-Host -ForegroundColor Red $line
        } else {
            Write-Host $line
        }
    }
}


$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName

if ($DeploymentName -eq "") {
    $deployment = Get-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
        | Sort-Object -Property Timestamp -Descending `
        | Select-Object -First 1 
    $DeploymentName = $deployment.DeploymentName
}

function GetDeployments($deploymentName) {
    $deployment = Get-AzureRmResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -Name $deploymentName `
        -ErrorAction SilentlyContinue

    if ($deployment -eq $null) {
        return $null
    }

    $operations = GetOperations $deployment

    $deploymentSummary = [PSCustomObject]@{Deployment = $deployment; Operations = $operations};
    $deployments = @($deploymentSummary)

    $nestedNames = $operations `
        | Where-Object { $_.ResourceType -eq "Microsoft.Resources/deployments" } `
        | Select-Object -ExpandProperty ResourceName 
    foreach ($nestedName in $nestedNames) {
        $nestedDeployments = GetDeployments $nestedName
        if ($nestedDeployments -ne $null) {
            $deployments = $deployments + $nestedDeployments
        }
    }

    return $deployments
}


do {
    $deployments = GetDeployments $DeploymentName

    if ($deployments -eq $null) {
        Write-Host "No deployments"
        exit
    }
    Clear-Host
    foreach ($summary in $deployments) {
        $deployment = $summary.Deployment
        $operations = $summary.Operations
        Write-Host "Deployment: $($deployment.DeploymentName) ($($deployment.ProvisioningState))"
        DumpOperations $operations
    }

    if ($deployments[0].Deployment.ProvisioningState -ne "Running") {
        Write-Host "Deployment finished"
        exit
    }

    Start-Sleep -Seconds 10 # TODO - set this to a sensible time!
} while ( $true) 


