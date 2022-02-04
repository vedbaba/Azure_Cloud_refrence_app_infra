#Login-AzureRmAccount
#$PSVersionTable.PSVersion

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "myapp-digitalplatform-sandpit-rg",
    # The name of arm template file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile = "azuredeploy.json",
    # The name of deployment
    [Parameter(Mandatory = $false)]
    [string]$deploymentname = "appinsight_deployment",
    # The name of appinsight prefix
    [Parameter(Mandatory = $false)]
    [string]$appinsightprefixname = "Myapp",
    # The name of environment
    [Parameter(Mandatory = $false)]
    [string]$environment = "nonprod",
    # The name of costcenter
    [Parameter(Mandatory = $false)]
    [string]$costcenter = "LRSB",
    # The name of app owner
    [Parameter(Mandatory = $false)]
    [string]$owner = "schemes",
    # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ', '_'), '3.0.0')
}
catch { }


$lrTemplatefile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile))

$ParametersObj = @{
    appinsightname=$appinsightprefixname
    environment=$environment
    costcenter=$costcenter
    owner = $owner
}



$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile `
            -TemplateParameterObject $ParametersObj)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    #Start the 1st deployment to create sql server and database instances
    New-AzResourceGroupDeployment -Name ($deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile `
        -TemplateParameterObject $ParametersObj `
        -Force -Verbose

}


#Remove-AzureRmAlertRule -ResourceGroup "Default-Web-CentralUS" -Name "myalert-7da64548-214d-42ca-b12b-b245bb8f0ac8"
#Remove-AzureRmAutoscaleSetting  -ResourceGroup "myapp-digitalplatform-sandpit-rg" -Name "myapp-schemes-serviceplan-nonprod-myapp-digitalplatform-sandpit-rg"

