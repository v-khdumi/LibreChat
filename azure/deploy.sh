#!/bin/bash

# Azure Deployment Script for LibreChat
# This script deploys LibreChat to Azure App Service using ARM templates

set -e

# Configuration
RESOURCE_GROUP_NAME="librechat-rg"
LOCATION="East US"
TEMPLATE_FILE="azure/azure-resources-template.json"
PARAMETERS_FILE="azure/azure-resources-parameters.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        print_error "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI is installed"
}

# Check if user is logged in
check_azure_login() {
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    CURRENT_SUBSCRIPTION=$(az account show --query name --output tsv)
    print_success "Logged in to Azure subscription: $CURRENT_SUBSCRIPTION"
}

# Create resource group
create_resource_group() {
    print_status "Creating resource group: $RESOURCE_GROUP_NAME"
    
    if az group exists --name $RESOURCE_GROUP_NAME --output tsv | grep -q "true"; then
        print_warning "Resource group $RESOURCE_GROUP_NAME already exists"
    else
        az group create \
            --name $RESOURCE_GROUP_NAME \
            --location "$LOCATION"
        print_success "Resource group $RESOURCE_GROUP_NAME created"
    fi
}

# Validate ARM template
validate_template() {
    print_status "Validating ARM template..."
    
    az deployment group validate \
        --resource-group $RESOURCE_GROUP_NAME \
        --template-file $TEMPLATE_FILE \
        --parameters $PARAMETERS_FILE
        
    if [ $? -eq 0 ]; then
        print_success "ARM template validation passed"
    else
        print_error "ARM template validation failed"
        exit 1
    fi
}

# Deploy resources
deploy_resources() {
    print_status "Deploying resources to Azure..."
    
    DEPLOYMENT_NAME="librechat-deployment-$(date +%Y%m%d%H%M%S)"
    
    az deployment group create \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $DEPLOYMENT_NAME \
        --template-file $TEMPLATE_FILE \
        --parameters $PARAMETERS_FILE \
        --verbose
    
    if [ $? -eq 0 ]; then
        print_success "Deployment completed successfully"
        
        # Get the web app URL
        WEB_APP_URL=$(az deployment group show \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $DEPLOYMENT_NAME \
            --query properties.outputs.webAppUrl.value \
            --output tsv)
        
        print_success "LibreChat deployed to: $WEB_APP_URL"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Configure additional settings
configure_app_settings() {
    print_status "Configuring additional app settings..."
    
    WEBAPP_NAME=$(az deployment group show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $(az deployment group list \
            --resource-group $RESOURCE_GROUP_NAME \
            --query '[0].name' --output tsv) \
        --query properties.parameters.siteName.value \
        --output tsv)
    
    # Add any additional configuration here
    print_success "App settings configured"
}

# Show deployment information
show_deployment_info() {
    print_status "Deployment Summary:"
    echo "==================="
    echo "Resource Group: $RESOURCE_GROUP_NAME"
    echo "Location: $LOCATION"
    
    # Get web app URL
    WEB_APP_URL=$(az webapp show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $(az webapp list --resource-group $RESOURCE_GROUP_NAME --query '[0].name' --output tsv) \
        --query defaultHostName \
        --output tsv)
    
    echo "Web App URL: https://$WEB_APP_URL"
    echo "==================="
    
    print_success "LibreChat is now deployed to Azure App Service!"
    print_warning "Remember to configure your OpenAI API keys and other environment variables in the Azure portal."
}

# Main execution
main() {
    echo "============================================"
    echo "  LibreChat Azure App Service Deployment  "
    echo "============================================"
    echo
    
    check_azure_cli
    check_azure_login
    create_resource_group
    validate_template
    deploy_resources
    configure_app_settings
    show_deployment_info
}

# Help function
show_help() {
    echo "LibreChat Azure Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -g, --group    Resource group name (default: $RESOURCE_GROUP_NAME)"
    echo "  -l, --location Location (default: $LOCATION)"
    echo
    echo "Example:"
    echo "  $0 --group my-librechat-rg --location \"West Europe\""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -g|--group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main