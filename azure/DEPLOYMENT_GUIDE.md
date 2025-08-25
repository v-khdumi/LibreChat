# LibreChat Azure App Service Deployment Guide

Această documentație te va ghida prin procesul de deploy al LibreChat pe Azure App Service (WebApp).

## Prezentare generală

Această configurație de deploy va crea următoarele resurse Azure:
- **Azure App Service**: Pentru hosting-ul aplicației LibreChat
- **Azure Cosmos DB** (MongoDB API): Pentru stocarea datelor
- **Azure Storage Account**: Pentru stocarea fișierelor uploadate
- **App Service Plan**: Pentru resursele compute

## Cerințe preliminare

1. **Azure CLI** instalat și configurat
   ```bash
   # Instalare Azure CLI (pe Windows, macOS, Linux)
   # Vezi: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   
   # Login în Azure
   az login
   ```

2. **Subscripție Azure activă**

3. **Git repository** cu codul LibreChat

## Metode de deployment

### Metoda 1: Deployment automatizat cu script

1. **Rulează scriptul de deployment**:
   ```bash
   # Din directorul rădăcină al proiectului
   chmod +x azure/deploy.sh
   ./azure/deploy.sh
   ```

2. **Sau cu parametri customizați**:
   ```bash
   ./azure/deploy.sh --group "my-librechat-rg" --location "West Europe"
   ```

### Metoda 2: Deployment manual cu ARM Templates

1. **Creează un resource group**:
   ```bash
   az group create --name librechat-rg --location "East US"
   ```

2. **Deploy template-ul ARM**:
   ```bash
   az deployment group create \
     --resource-group librechat-rg \
     --template-file azure/azure-resources-template.json \
     --parameters azure/azure-resources-parameters.json
   ```

### Metoda 3: GitHub Actions Deployment

1. **Configurează secretele în GitHub**:
   - `AZURE_CREDENTIALS`: JSON cu credențialele service principal-ului Azure

2. **Creează un service principal Azure**:
   ```bash
   az ad sp create-for-rbac \
     --name "librechat-github-actions" \
     --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
     --sdk-auth
   ```

3. **Copiază output-ul JSON în GitHub Secrets ca `AZURE_CREDENTIALS`**

4. **Push code-ul pe branch-ul main** pentru a declanșa deployment-ul automat

## Configurarea mediului

### 1. Variabile de mediu esențiale

După deployment, configurează următoarele în **Azure Portal > App Service > Configuration**:

```bash
# Database
MONGO_URI=mongodb://your-cosmosdb:key@your-cosmosdb.mongo.cosmos.azure.com:10255/LibreChat?ssl=true&replicaSet=globaldb

# Storage
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=your-storage;AccountKey=your-key;EndpointSuffix=core.windows.net

# Security
JWT_SECRET=your-secure-jwt-secret
JWT_REFRESH_SECRET=your-secure-refresh-secret
CREDS_KEY=your-secure-creds-key
CREDS_IV=your-secure-creds-iv

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Azure OpenAI (opțional)
AZURE_API_KEY=your-azure-openai-key
AZURE_OPENAI_API_INSTANCE_NAME=your-instance
AZURE_OPENAI_API_DEPLOYMENT_NAME=your-deployment
```

### 2. Configurarea domeniului

1. **Actualizează domeniile în configurație**:
   ```bash
   DOMAIN_CLIENT=https://your-webapp-name.azurewebsites.net
   DOMAIN_SERVER=https://your-webapp-name.azurewebsites.net
   ```

2. **Pentru domeniu custom** (opțional):
   - Adaugă domeniul custom în Azure Portal
   - Configurează certificate SSL
   - Actualizează variabilele de mediu cu noul domeniu

## Monitorizare și troubleshooting

### 1. Loguri aplicație

```bash
# Vezi logurile din Azure CLI
az webapp log tail --name your-webapp-name --resource-group librechat-rg

# Sau din Azure Portal
# App Service > Monitoring > Log stream
```

### 2. Probleme comune

#### Aplicația nu pornește
- Verifică dacă `MONGO_URI` este configurat corect
- Verifică logurile pentru erori de build
- Asigură-te că toate dependențele sunt instalate

#### Erori de bază de date
- Verifică connection string-ul Cosmos DB
- Verifică firewall settings pentru Cosmos DB
- Asigură-te că database-ul LibreChat există

#### Erori de storage
- Verifică connection string-ul Storage Account
- Verifică dacă container-ul 'uploads' există
- Verifică permisiunile pentru blob storage

### 3. Scaling și performanță

```bash
# Scale up App Service Plan
az appservice plan update \
  --name librechat-app-service-plan \
  --resource-group librechat-rg \
  --sku S2

# Scale out (mai multe instanțe)
az webapp update \
  --name your-webapp-name \
  --resource-group librechat-rg \
  --instance-count 3
```

## Securitate

### 1. Securizarea bazei de date
- Activează firewall-ul pentru Cosmos DB
- Configurează access keys rotation
- Folosește Managed Identity când este posibil

### 2. Securizarea storage-ului
- Configurează SAS tokens pentru access controlat
- Activează encryption at rest
- Configurează network access rules

### 3. App Service Security
- Activează HTTPS only
- Configurează custom domains cu SSL
- Folosește Azure Key Vault pentru secrete

## Costuri estimate

Pentru o aplicație mică-medie:
- **App Service Plan B2**: ~$35/lună
- **Cosmos DB (400 RU/s)**: ~$24/lună  
- **Storage Account**: ~$2-5/lună

**Total estimate**: ~$60-65/lună

Pentru production:
- **App Service Plan S2**: ~$73/lună
- **Cosmos DB (1000 RU/s)**: ~$58/lună
- **Storage Account**: ~$5-10/lună

**Total estimate**: ~$135-140/lună

## Backup și disaster recovery

### 1. Backup bază de date
```bash
# Automated backup pentru Cosmos DB (activat automat)
# Point-in-time restore disponibil

# Manual export
az cosmosdb sql database export \
  --account-name your-cosmosdb \
  --resource-group librechat-rg \
  --name LibreChat
```

### 2. Backup aplicație
```bash
# App Service backup
az webapp config backup create \
  --webapp-name your-webapp-name \
  --resource-group librechat-rg \
  --storage-account-url your-backup-url
```

## Update și maintenance

### 1. Update aplicație
- Push pe GitHub pentru deployment automat (cu GitHub Actions)
- Sau redeploy manual cu Azure CLI

### 2. Update dependențe
```bash
# Update packages
npm update

# Rebuild și redeploy
npm run frontend
```

### 3. Monitorizare continuă
- Configurează Application Insights
- Set up alerting pentru downtime
- Monitorizează performance metrics

## Support și troubleshooting

Pentru probleme și întrebări:
1. Verifică Azure Portal > App Service > Diagnose and solve problems
2. Consultă logurile aplicației
3. Verifică documentația LibreChat oficială
4. Contactează support-ul Azure pentru probleme de infrastructură

---

**Nota**: Această configurație este optimizată pentru deployment production. Pentru development, poți folosi tier-uri mai mici pentru a reduce costurile.