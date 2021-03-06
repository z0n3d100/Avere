﻿param (
    # Set a naming prefix for the Azure resource groups that are created by this deployment script
    [string] $resourceGroupNamePrefix = "Azure.Media.Studio",

    # Set to 1 or more Azure region names (http://azure.microsoft.com/global-infrastructure/regions)
    [string[]] $computeRegionNames = @("WestUS2"),

    # Set to 1 or more Azure region names (http://azure.microsoft.com/global-infrastructure/regions)
    [string[]] $storageRegionNames = @("WestUS2"),

    # Set to true to deploy Azure NetApp Files (http://docs.microsoft.com/azure/azure-netapp-files/azure-netapp-files-introduction)
    [boolean] $storageNetAppEnable = $false,

    # Set to true to deploy Azure Object (Blob) Storage (http://docs.microsoft.com/azure/storage/blobs/storage-blobs-overview)
    [boolean] $storageObjectEnable = $false,

    # Set to true to deploy Azure HPC Cache (https://docs.microsoft.com/en-us/azure/hpc-cache/hpc-cache-overview)
    [boolean] $cacheEnable = $false,

    # The set of shared Azure services across regions, including Storage, Cache, Image Gallery, etc.
    [object] $sharedServices
)

$templateDirectory = $PSScriptRoot
if (!$templateDirectory) {
    $templateDirectory = $using:templateDirectory
}

Import-Module "$templateDirectory/Deploy.psm1"

# * - Shared Services Job
if (!$sharedServices) {
    $moduleName = "* - Shared Services Job"
    New-TraceMessage $moduleName $false
    $sharedServicesJob = Start-Job -FilePath "$templateDirectory/Deploy.SharedServices.ps1" -ArgumentList $resourceGroupNamePrefix, $computeRegionNames, $storageRegionNames, $storageNetAppEnable, $storageObjectEnable, $cacheEnable
    $sharedServices = Receive-Job -Job $sharedServicesJob -Wait
    if ($sharedServicesJob.JobStateInfo.State -eq "Failed") {
        Write-Host $sharedServicesJob.JobStateInfo.Reason
        return
    }
    New-TraceMessage $moduleName $true
}

$computeNetworks = $sharedServices.computeNetworks
$managedIdentity = $sharedServices.managedIdentity
$logAnalytics = $sharedServices.logAnalytics
$imageGallery = $sharedServices.imageGallery
$storageMounts = $sharedServices.storageMounts

$moduleDirectory = "RenderManager"

# 05 - Manager Data
$managerDatabaseSql = @()
$managerDatabaseAdminName = @()
$managerDatabaseAdminLogin = @()
$managerDatabaseAdminPassword = @()
$managerDatabaseUrl = @()
$managerDatabaseUserName = @()
$managerDatabaseUserLogin = @()
$managerDatabaseUserPassword = @()
$moduleName = "05 - Manager Data"
$resourceGroupNameSuffix = "Manager"
New-TraceMessage $moduleName $false
for ($computeRegionIndex = 0; $computeRegionIndex -lt $computeRegionNames.length; $computeRegionIndex++) {
    $computeRegionName = $computeRegionNames[$computeRegionIndex]
    New-TraceMessage $moduleName $false $computeRegionName
    $resourceGroupName = Get-ResourceGroupName $resourceGroupNamePrefix $resourceGroupNameSuffix $computeRegionIndex
    $resourceGroup = az group create --resource-group $resourceGroupName --location $computeRegionName
    if (!$resourceGroup) { return }
    
    $templateResources = "$templateDirectory/$moduleDirectory/05-Manager.Data.json"
    $templateParameters = (Get-Content "$templateDirectory/$moduleDirectory/05-Manager.Data.Parameters.$computeRegionName.json" -Raw | ConvertFrom-Json).parameters

    if ($templateParameters.virtualNetwork.value.name -eq "") {
        $templateParameters.virtualNetwork.value.name = $computeNetworks[$computeRegionIndex].name
    }
    if ($templateParameters.virtualNetwork.value.resourceGroupName -eq "") {
        $templateParameters.virtualNetwork.value.resourceGroupName = $computeNetworks[$computeRegionIndex].resourceGroupName
    }
    
    $templateParameters = '"{0}"' -f ($templateParameters | ConvertTo-Json -Compress).Replace('"', '\"')
    $groupDeployment = (az deployment group create --resource-group $resourceGroupName --template-file $templateResources --parameters $templateParameters) | ConvertFrom-Json
    if (!$groupDeployment) { return }

    $managerDatabaseSql += $groupDeployment.properties.outputs.managerDatabaseSql.value
    $managerDatabaseAdminName += $groupDeployment.properties.outputs.managerDatabaseAdminName.value
    $managerDatabaseAdminLogin += $groupDeployment.properties.outputs.managerDatabaseAdminLogin.value
    $managerDatabaseAdminPassword += $groupDeployment.properties.outputs.managerDatabaseAdminPassword.value
    $managerDatabaseUrl += $groupDeployment.properties.outputs.managerDatabaseUrl.value
    $managerDatabaseUserName += $groupDeployment.properties.outputs.managerDatabaseUserName.value
    $managerDatabaseUserLogin += $groupDeployment.properties.outputs.managerDatabaseUserLogin.value
    $managerDatabaseUserPassword += $groupDeployment.properties.outputs.managerDatabaseUserPassword.value
    New-TraceMessage $moduleName $true $computeRegionName
}
New-TraceMessage $moduleName $true

# 06.0 - Manager Image Template
$computeRegionIndex = 0
$moduleName = "06.0 - Manager Image Template"
$resourceGroupNameSuffix = "Image"
New-TraceMessage $moduleName $false $computeRegionNames[$computeRegionIndex]
$resourceGroupName = Get-ResourceGroupName $resourceGroupNamePrefix $resourceGroupNameSuffix
$resourceGroup = az group create --resource-group $resourceGroupName --location $computeRegionNames[$computeRegionIndex]
if (!$resourceGroup) { return }

$templateResources = "$templateDirectory/$moduleDirectory/06-Manager.Images.json"
$templateParameters = (Get-Content "$templateDirectory/$moduleDirectory/06-Manager.Images.Parameters.json" -Raw | ConvertFrom-Json).parameters

if ($templateParameters.renderManager.value.userIdentityId -eq "") {
    $templateParameters.renderManager.value.userIdentityId = $managedIdentity.userResourceId
}
for ($machineImageIndex = 0; $machineImageIndex -lt $templateParameters.renderManager.value.machineImages.length; $machineImageIndex++) {
    if ($templateParameters.renderManager.value.machineImages[$machineImageIndex].customizePipeline[1].inline.length -eq 0) {
        $imageDefinitionName = $templateParameters.renderManager.value.machineImages[$machineImageIndex].definitionName
        $storageMountCommands = Get-StorageMountCommands $imageGallery $imageDefinitionName $storageMounts
        $templateParameters.renderManager.value.machineImages[$machineImageIndex].customizePipeline[1].inline = $storageMountCommands
    }
}
if ($templateParameters.imageGallery.value.name -eq "") {
    $templateParameters.imageGallery.value.name = $imageGallery.name
}
if ($templateParameters.imageGallery.value.imageReplicationRegions.length -eq 0) {
    $templateParameters.imageGallery.value.imageReplicationRegions = $computeRegionNames
}
if ($templateParameters.virtualNetwork.value.name -eq "") {
    $templateParameters.virtualNetwork.value.name = $computeNetworks[$computeRegionIndex].name
}
if ($templateParameters.virtualNetwork.value.resourceGroupName -eq "") {
    $templateParameters.virtualNetwork.value.resourceGroupName = $computeNetworks[$computeRegionIndex].resourceGroupName
}

$templateParameters = '"{0}"' -f ($templateParameters | ConvertTo-Json -Compress -Depth 7).Replace('"', '\"')
$groupDeployment = (az deployment group create --resource-group $resourceGroupName --template-file $templateResources --parameters $templateParameters) | ConvertFrom-Json
# if (!$groupDeployment) { return }
New-TraceMessage $moduleName $true $computeRegionNames[$computeRegionIndex]

# 06.1 - Manager Image Version
$computeRegionIndex = 0
$moduleName = "06.1 - Manager Image Version"
$resourceGroupNameSuffix = "Image"
New-TraceMessage $moduleName $false $computeRegionNames[$computeRegionIndex]
$resourceGroupName = Get-ResourceGroupName $resourceGroupNamePrefix $resourceGroupNameSuffix
$templateParameters = (Get-Content "$templateDirectory/$moduleDirectory/06-Manager.Images.Parameters.json" -Raw | ConvertFrom-Json).parameters
foreach ($machineImage in $templateParameters.renderManager.value.machineImages) {
    if ($machineImage.enabled) {
        New-TraceMessage "$moduleName [$($machineImage.templateName)]" $false $computeRegionNames[$computeRegionIndex]
        $imageVersionId = Get-ImageVersionId $resourceGroupName $imageGallery.name $machineImage.definitionName $machineImage.templateName
        if (!$imageVersionId) {
            az image builder run --resource-group $resourceGroupName --name $machineImage.templateName
        }
        New-TraceMessage "$moduleName [$($machineImage.templateName)]" $true $computeRegionNames[$computeRegionIndex]
    }
}
New-TraceMessage $moduleName $true $computeRegionNames[$computeRegionIndex]

# 07 - Manager Machines
$renderManagers = @()
$moduleName = "07 - Manager Machines"
$resourceGroupNameSuffix = "Manager"
New-TraceMessage $moduleName $false
for ($computeRegionIndex = 0; $computeRegionIndex -lt $computeRegionNames.length; $computeRegionIndex++) {
    New-TraceMessage $moduleName $false $computeRegionNames[$computeRegionIndex]
    $resourceGroupName = Get-ResourceGroupName $resourceGroupNamePrefix $resourceGroupNameSuffix $computeRegionIndex
    $resourceGroup = az group create --resource-group $resourceGroupName --location $computeRegionNames[$computeRegionIndex]
    if (!$resourceGroup) { return }

    $templateResources = "$templateDirectory/$moduleDirectory/07-Manager.Machines.json"
    $templateParameters = (Get-Content "$templateDirectory/$moduleDirectory/07-Manager.Machines.Parameters.json" -Raw | ConvertFrom-Json).parameters
    $scriptCommands = Get-ScriptCommands "$templateDirectory/$moduleDirectory/07-Manager.Machines.sh"

    if ($templateParameters.renderManager.value.image.referenceId -eq "") {
        $imageTemplateName = $templateParameters.renderManager.value.image.templateName
        $imageDefinitionName = $templateParameters.renderManager.value.image.definitionName
        $imageVersionId = Get-ImageVersionId $imageGallery.resourceGroupName $imageGallery.name $imageDefinitionName $imageTemplateName
        $templateParameters.renderManager.value.image.referenceId = $imageVersionId
    }
    if ($templateParameters.renderManager.value.scriptCommands -eq "") {
        $templateParameters.renderManager.value.scriptCommands = $scriptCommands
    }
    if ($templateParameters.renderManager.value.databaseSql -eq "") {
        $templateParameters.renderManager.value.databaseSql = $managerDatabaseSql[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseAdminName -eq "") {
        $templateParameters.renderManager.value.databaseAdminName = $managerDatabaseAdminName[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseAdminLogin -eq "") {
        $templateParameters.renderManager.value.databaseAdminLogin = $managerDatabaseAdminLogin[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseAdminPassword -eq "") {
        $templateParameters.renderManager.value.databaseAdminPassword = $managerDatabaseAdminPassword[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseUrl -eq "") {
        $templateParameters.renderManager.value.databaseUrl = $managerDatabaseUrl[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseUserName -eq "") {
        $templateParameters.renderManager.value.databaseUserName = $managerDatabaseUserName[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseUserLogin -eq "") {
        $templateParameters.renderManager.value.databaseUserLogin = $managerDatabaseUserLogin[$computeRegionIndex]
    }
    if ($templateParameters.renderManager.value.databaseUserPassword -eq "") {
        $templateParameters.renderManager.value.databaseUserPassword = $managerDatabaseUserPassword[$computeRegionIndex]
    }
    # if ($templateParameters.logAnalytics.value.workspaceId -eq "") {
    #     $templateParameters.logAnalytics.value.workspaceId = $logAnalytics.workspaceId
    # }
    # if ($templateParameters.logAnalytics.value.workspaceKey -eq "") {
    #     $templateParameters.logAnalytics.value.workspaceKey = $logAnalytics.workspaceKey
    # }
    if ($templateParameters.virtualNetwork.value.name -eq "") {
        $templateParameters.virtualNetwork.value.name = $computeNetworks[$computeRegionIndex].name
    }
    if ($templateParameters.virtualNetwork.value.resourceGroupName -eq "") {
        $templateParameters.virtualNetwork.value.resourceGroupName = $computeNetworks[$computeRegionIndex].resourceGroupName
    }

    $templateParameters = '"{0}"' -f ($templateParameters | ConvertTo-Json -Compress -Depth 4).Replace('"', '\"')
    $groupDeployment = (az deployment group create --resource-group $resourceGroupName --template-file $templateResources --parameters $templateParameters) | ConvertFrom-Json
    if (!$groupDeployment) { return }
    
    $renderManagers += $groupDeployment.properties.outputs.renderManager.value
    New-TraceMessage $moduleName $true $computeRegionNames[$computeRegionIndex]
}
New-TraceMessage $moduleName $true

Write-Output -InputObject $renderManagers -NoEnumerate
