# LibreChat Azure Deployment PowerShell Script
# This script deploys LibreChat to Azure App Service using ARM templates

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "librechat-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "azure/azure-resources-template.json",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "azure/azure-resources-parameters.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Help function
function Show-Help {
    Write-Host "LibreChat Azure Deployment Script" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -ResourceGroupName    Resource group name (default: librechat-rg)"
    Write-Host "  -Location            Location (default: East US)"
    Write-Host "  -TemplateFile        ARM template file path"
    Write-Host "  -ParametersFile      ARM parameters file path"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Green
    Write-Host '  .\deploy.ps1 -ResourceGroupName "my-librechat-rg" -Location "West Europe"'
    Write-Host ""
}

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if Azure CLI is installed
function Test-AzureCLI {
    try {
        $azVersion = az --version
        if ($azVersion) {
            Write-Success "Azure CLI is installed"
            return $true
        }
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it first."
        Write-Error "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return $false
    }
}

# Function to check if user is logged in
function Test-AzureLogin {
    try {
        $account = az account show --output json | ConvertFrom-Json
        if ($account) {
            Write-Success "Logged in to Azure subscription: $($account.name)"
            return $true
        }
    }
    catch {
        Write-Warning "Not logged in to Azure. Please run 'az login' first."
        return $false
    }
}

# Function to create resource group
function New-ResourceGroup {
    Write-Status "Creating resource group: $ResourceGroupName"
    
    $existingGroup = az group exists --name $ResourceGroupName --output tsv
    if ($existingGroup -eq "true") {
        Write-Warning "Resource group $ResourceGroupName already exists"
    }
    else {
        az group create --name $ResourceGroupName --location $Location --output table
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Resource group $ResourceGroupName created"
        }
        else {
            Write-Error "Failed to create resource group"
            exit 1
        }
    }
}

# Function to validate ARM template
function Test-Template {
    Write-Status "Validating ARM template..."
    
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file $TemplateFile `
        --parameters $ParametersFile `
        --output table
        
    if ($LASTEXITCODE -eq 0) {
        Write-Success "ARM template validation passed"
    }
    else {
        Write-Error "ARM template validation failed"
        exit 1
    }
}

# Function to deploy resources
function Deploy-Resources {
    Write-Status "Deploying resources to Azure..."
    
    $deploymentName = "librechat-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    az deployment group create `
        --resource-group $ResourceGroupName `
        --name $deploymentName `
        --template-file $TemplateFile `
        --parameters $ParametersFile `
        --output table
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment completed successfully"
        
        # Get the web app URL
        $deployment = az deployment group show `
            --resource-group $ResourceGroupName `
            --name $deploymentName `
            --output json | ConvertFrom-Json
            
        $webAppUrl = $deployment.properties.outputs.webAppUrl.value
        Write-Success "LibreChat deployed to: $webAppUrl"
        
        return $webAppUrl
    }
    else {
        Write-Error "Deployment failed"
        exit 1
    }
}

# Function to show deployment information
function Show-DeploymentInfo {
    param([string]$WebAppUrl)
    
    Write-Status "Deployment Summary:"
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Location: $Location"
    Write-Host "Web App URL: $WebAppUrl"
    Write-Host "===================" -ForegroundColor Cyan
    
    Write-Success "LibreChat is now deployed to Azure App Service!"
    Write-Warning "Remember to configure your OpenAI API keys and other environment variables in the Azure portal."
}

# Main execution
function Main {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  LibreChat Azure App Service Deployment  " -ForegroundColor Cyan  
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check prerequisites
    if (-not (Test-AzureCLI)) { exit 1 }
    if (-not (Test-AzureLogin)) { exit 1 }
    
    # Check if template files exist
    if (-not (Test-Path $TemplateFile)) {
        Write-Error "Template file not found: $TemplateFile"
        exit 1
    }
    
    if (-not (Test-Path $ParametersFile)) {
        Write-Error "Parameters file not found: $ParametersFile"  
        exit 1
    }
    
    # Execute deployment steps
    New-ResourceGroup
    Test-Template
    $webAppUrl = Deploy-Resources
    Show-DeploymentInfo -WebAppUrl $webAppUrl
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Deployment failed with error: $($_.Exception.Message)"
    exit 1
}