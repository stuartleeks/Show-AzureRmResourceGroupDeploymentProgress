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