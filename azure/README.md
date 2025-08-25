# LibreChat Azure Deployment

This directory contains all the necessary files to deploy LibreChat to Azure App Service (WebApp).

## 📁 Files Overview

| File | Description |
|------|-------------|
| `azure-resources-template.json` | ARM template for creating Azure resources |
| `azure-resources-parameters.json` | Parameters file for the ARM template |
| `librechat.bicep` | Bicep template (alternative to ARM JSON) |
| `deploy.sh` | Bash deployment script for Linux/macOS |
| `deploy.ps1` | PowerShell deployment script for Windows |
| `azure-config.json` | Azure-specific configuration settings |
| `.env.azure.example` | Example environment variables for Azure |
| `DEPLOYMENT_GUIDE.md` | Comprehensive deployment guide (in Romanian) |

## 🚀 Quick Start

### Option 1: Automated Script Deployment (Recommended)

#### Linux/macOS:
```bash
chmod +x azure/deploy.sh
./azure/deploy.sh
```

#### Windows (PowerShell):
```powershell
.\azure\deploy.ps1
```

### Option 2: Manual ARM Template Deployment

```bash
# Login to Azure
az login

# Create resource group
az group create --name librechat-rg --location "East US"

# Deploy resources
az deployment group create \
  --resource-group librechat-rg \
  --template-file azure/azure-resources-template.json \
  --parameters azure/azure-resources-parameters.json
```

### Option 3: GitHub Actions Deployment

1. Configure `AZURE_CREDENTIALS` secret in your GitHub repository
2. Push to main branch to trigger automatic deployment

## 🎯 What Gets Deployed

The deployment creates the following Azure resources:

- **App Service Plan** (Linux, Node.js 20.x)
- **App Service** (Web App)
- **Cosmos DB** (MongoDB API) 
- **Storage Account** (for file uploads)
- **Application Insights** (monitoring - optional)

## ⚙️ Configuration

### Required Environment Variables

After deployment, configure these in Azure Portal > App Service > Configuration:

```bash
# Essential
MONGO_URI=mongodb://your-cosmosdb:key@your-cosmosdb.mongo.cosmos.azure.com:10255/LibreChat?ssl=true&replicaSet=globaldb
OPENAI_API_KEY=your-openai-api-key
JWT_SECRET=your-secure-jwt-secret
JWT_REFRESH_SECRET=your-secure-refresh-secret

# Azure Storage
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...
FILE_STRATEGY=azure

# Optional: Azure OpenAI
AZURE_API_KEY=your-azure-openai-key
AZURE_OPENAI_API_INSTANCE_NAME=your-instance
```

See `.env.azure.example` for complete configuration options.

## 📊 Estimated Costs

### Development/Small Scale
- App Service Plan B2: ~$35/month
- Cosmos DB (400 RU/s): ~$24/month
- Storage Account: ~$2-5/month
- **Total: ~$60-65/month**

### Production Scale
- App Service Plan S2: ~$73/month  
- Cosmos DB (1000 RU/s): ~$58/month
- Storage Account: ~$5-10/month
- **Total: ~$135-140/month**

## 🔧 Troubleshooting

### Common Issues

1. **App won't start**
   - Check `MONGO_URI` configuration
   - Verify build logs in Azure Portal
   - Ensure all dependencies are installed

2. **Database connection errors**
   - Verify Cosmos DB connection string
   - Check firewall settings
   - Ensure database exists

3. **File upload issues**
   - Verify Storage Account connection string
   - Check if 'uploads' container exists
   - Verify blob permissions

### Viewing Logs

```bash
# Stream logs from Azure CLI
az webapp log tail --name your-webapp-name --resource-group librechat-rg

# Or view in Azure Portal
# App Service > Monitoring > Log stream
```

## 📈 Scaling

### Scale Up (More CPU/Memory)
```bash
az appservice plan update \
  --name librechat-app-service-plan \
  --resource-group librechat-rg \
  --sku S2
```

### Scale Out (More Instances)
```bash
az webapp update \
  --name your-webapp-name \
  --resource-group librechat-rg \
  --instance-count 3
```

## 🔒 Security Best Practices

1. **Use Azure Key Vault** for sensitive configuration
2. **Enable HTTPS only** in App Service settings
3. **Configure custom domains** with SSL certificates
4. **Set up firewall rules** for Cosmos DB
5. **Enable diagnostic logging** and monitoring

## 🆕 Updates

### Automatic Updates (GitHub Actions)
- Push to main branch triggers redeployment
- Uses the workflow in `.github/workflows/deploy-azure.yml`

### Manual Updates
```bash
# Redeploy with new code
az webapp deployment source sync \
  --name your-webapp-name \
  --resource-group librechat-rg
```

## 📝 Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Cosmos DB MongoDB API](https://docs.microsoft.com/en-us/azure/cosmos-db/mongodb/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [LibreChat Documentation](https://docs.librechat.ai/)

## 🐛 Support

For deployment issues:
1. Check the deployment logs in Azure Portal
2. Review the troubleshooting section above
3. Consult the comprehensive guide in `DEPLOYMENT_GUIDE.md`
4. Open an issue in the LibreChat repository

---

**Note**: This deployment is optimized for production use. For development, consider using smaller service tiers to reduce costs.