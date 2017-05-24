# Show-AzureRmResourceGroupDeploymentStatus.ps1

A little script designed to make it easier to track the progress of a large deployment with [Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#template-deployment)


## Requirements
[Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/overview) must be installed


 ## Running 
 
 Ensure that you are authenticated with Azure PowerShell.

 To show the status for the latest deployment
 ```powershell
    ./Show-AzureRmResourceGroupDeploymentStatus.ps1 -ResourceGroupName MyResourceGroup
 ```

  To show the status for a named deployment:
 ```powershell
    ./Show-AzureRmResourceGroupDeploymentStatus.ps1 -ResourceGroupName MyResourceGroup -DeploymentName MyDeployment
 ```

## TODO

My notes on things to do:

 * Look at the sorting as line items seem to jump around occasionally :-(
 * Perform all of the querying before outputting. For single deployments this isn't an issue, but when there are nested deployments there's a lag while retrieving the nested deployment status before it is output



