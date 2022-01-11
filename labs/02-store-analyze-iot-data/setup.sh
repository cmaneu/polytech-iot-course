printf "\e[44m\n*** AZURE SYNAPSE Workshop Creation on Subscription #$SUBSCRIPTION_ID ***\n\e[0m"
SUBSCRIPTION_ID=`az account show --query id --output tsv`
MAIN_REGION=westeurope

printf "\e[44m\n*** Working on on Subscription #$SUBSCRIPTION_ID and region $MAIN_REGION***\n\e[0m"

read -p 'New resource group name: ' RESOURCE_GROUP_NAME
read -p 'Unique prefix (applied to all resources): ' RESOURCE_PREFIX

STORAGE_ACCOUNT_NAME="$RESOURCE_PREFIX"datalake

# Create resource group
printf "\e[44m\n*** Creating resource group $RESOURCE_GROUP_NAME ***\n\e[0m"
az group create -n $RESOURCE_GROUP_NAME -l $MAIN_REGION

# Create storage account to store IoT Hub messages
printf "\e[44m\n*** Creating storage account (Data Lake) $STORAGE_ACCOUNT_NAME ***\n\e[0m"
az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME -l $MAIN_REGION --sku Standard_LRS --kind StorageV2 --enable-hierarchical-namespace true

az storage fs create -n "raw-data" --account-name $STORAGE_ACCOUNT_NAME
az storage fs create -n "synapse-data" --account-name $STORAGE_ACCOUNT_NAME

STORAGE_ACCOUNT_CONNECTION_STRING=`az storage account show-connection-string -g $RESOURCE_GROUP_NAME -n $STORAGE_ACCOUNT_NAME -o tsv`
printf "\n   Storage Account CS:  $STORAGE_ACCOUNT_CONNECTION_STRING\n"

## Create a Synapse Workspace & Pool
printf "\n   - Creating Synapse Workspace\n" 
SYNAPSE_NAME="$RESOURCE_PREFIX"synapsews
az synapse workspace create --name $SYNAPSE_NAME -g $RESOURCE_GROUP_NAME \
--sql-admin-login-user demo \
--sql-admin-login-password Password123! \
--location $MAIN_REGION \
--storage-account $STORAGE_ACCOUNT_NAME --file-system "synapse-data"

az synapse workspace firewall-rule create --name allowAll --workspace-name $SYNAPSE_NAME \
--resource-group $RESOURCE_GROUP_NAME --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255

printf "\n\nHooray! Your workshop environment is now ready."
printf "\e[44m\n - Resource group: $RESOURCE_GROUP_NAME\n\e[0m"
printf " - Prefix: $RESOURCE_PREFIX\n"
printf " - Data Lake: $STORAGE_ACCOUNT_NAME\n"
printf " - Azure Synapse: $SYNAPSE_NAME.sql.azuresynapse.net\n"
printf "        Username: demo\n"
printf "        Password: Password123!\n"