
[CmdletBinding(SupportsShouldProcess = $true)]
param(

    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "myapp-dev-rg",
    # The name of sql server deployment
    [Parameter(Mandatory = $false)]
    [string]$sqldeploymentname = "sql_deployment",
    # The name of web/api app server deployment
    [Parameter(Mandatory = $false)]
    [string]$appdeploymentname = "app_deployment",

 # The name of file for ARM template for api management deployment
 [Parameter(Mandatory = $false)]
 [string]$lrTemplatefile_api_management = "..\arm_templates\api-management\azuredeploy.json",
 # The name of file for ARM template parameter for api management deployment
 [Parameter(Mandatory = $false)]
 [string]$lrTemplateparameterfile_api_management = "api-management\azuredeploy.parameters.json",

  # The name of file for ARM template for api management deployment
  [Parameter(Mandatory = $false)]
  [string]$lrTemplatefile_appinsightonly = "..\arm_templates\appinsightonly\azuredeploy.json",
  # The name of file for ARM template parameter for api management deployment
  [Parameter(Mandatory = $false)]
  [string]$lrTemplateparameterfile_appinsightonly = "appinsightonly\azuredeploy.parameters.json",

    # The name of file for ARM template for api management deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_keyvault = "..\arm_templates\key_vault\azuredeploy.json",
    # The name of file for ARM template parameter for api management deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_keyvault = "key_vault\azuredeploy.parameters.json",
  

    # The name of file for ARM template for sql server deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_sqlserver = "..\arm_templates\SQL_Server\azuredeploy.json",
    # The name of file for ARM template parameter for sql server deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_sqlserver = "SQL_Server\azuredeploy.parameters.json",
    # The name of file for ARM template for web/api app server deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_webapps = "..\arm_templates\webapps\azuredeploy.json",
    # The name of file for ARM template prameter for web/api app server deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_webapps = "webapps\azuredeploy.parameters.json",
    # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

$lrTemplatefile_api_management = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_api_management))
$lrTemplateparameterfile_api_management = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_api_management))
$lrTemplatefile_appinsightonly = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_appinsightonly))
$lrTemplateparameterfile_appinsightonly = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_appinsightonly))
$lrTemplatefile_keyvault = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_keyvault))
$lrTemplateparameterfile_keyvault = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_keyvault))
$lrTemplatefile_sqlserver = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_sqlserver))
$lrTemplateparameterfile_sqlserver = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_sqlserver))
$lrTemplatefile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_webapps))
$lrTemplateparameterfile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_webapps))


try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ', '_'), '3.0.0')
}
catch { }
$ErrorActionPreference = 'Stop'
$ErrorMessages = ''
Set-StrictMode -Version 3
function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($ValidateOnly) {

    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_api_management `
            -TemplateParameterFile $lrTemplateparameterfile_api_management )

            $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_appinsightonly `
            -TemplateParameterFile $lrTemplateparameterfile_appinsightonly )


            $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_keyvault `
            -TemplateParameterFile $lrTemplateparameterfile_keyvault )

         $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_sqlserver `
            -TemplateParameterFile $lrTemplateparameterfile_sqlserver )

    $ErrorMessages += Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_webapps `
            -TemplateParameterFile $lrTemplateparameterfile_webapps)


    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {

    Write-Output 'Start the 1st deployment to create API Management'
    New-AzResourceGroupDeployment -Name ($sqldeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
    -ResourceGroupName $resourcegroup `
    -TemplateFile $lrTemplatefile_sqlserver `
    -TemplateParameterFile $lrTemplateparameterfile_sqlserver `
    -Force -Verbose

    Write-Output 'Start the 2st deployment to create App insight only'
    New-AzResourceGroupDeployment -Name ($sqldeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
    -ResourceGroupName $resourcegroup `
    -TemplateFile $lrTemplatefile_sqlserver `
    -TemplateParameterFile $lrTemplateparameterfile_sqlserver `
    -Force -Verbose

    Write-Output 'Start the 3st deployment to create Keyvault'
    New-AzResourceGroupDeployment -Name ($sqldeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
    -ResourceGroupName $resourcegroup `
    -TemplateFile $lrTemplatefile_sqlserver `
    -TemplateParameterFile $lrTemplateparameterfile_sqlserver `
    -Force -Verbose


    Write-Output 'Start the 4st deployment to create sql server and database instances'
    New-AzResourceGroupDeployment -Name ($sqldeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
    -ResourceGroupName $resourcegroup `
    -TemplateFile $lrTemplatefile_sqlserver `
    -TemplateParameterFile $lrTemplateparameterfile_sqlserver `
    -Force -Verbose

   Write-Output 'Start the 5th deployment for [web/api]-apps server'
   New-AzResourceGroupDeployment -Name ($appdeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
   -ResourceGroupName $resourcegroup `
   -TemplateFile $lrTemplatefile_webapps `
   -TemplateParameterFile $lrTemplateparameterfile_webapps `
   -Force -Verbose


}