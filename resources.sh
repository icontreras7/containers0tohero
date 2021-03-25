#!/bin/bash

rg="containers0tohero" 
vnet="containersvnet" 
vm="buildvm" 
stdasubnet="standalone-subnet" 
akssubnet="aks-subnet"
location="eastus2"
admin="bigboss"
#Create the RG
az group create -n $rg -l $location

#Create VNet and subnets
az network vnet create \
    -n $vnet \
    -g $rg \
    -l $location \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $stdasubnet \
    --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
    --address-prefix 10.0.2.0/24 \
    -n $akssubnet \
    -g $rg \
    --vnet-name $vnet

#Create Ubuntu VM for Docker Steps
az vm create \
    -g $rg \
    -n $vm \
    --image UbuntuLTS \
    --size Standard_DS2 \
    --vnet-name $vnet \
    --subnet $stdasubnet \
    --admin-username $admin \
    --generate-ssh-keys

buildVmPublicIp=$(az vm show -d -g $rg -n $vm --query publicIps -o tsv)

echo "Your Public IP Address is: $buildVmPublicIp"

#Install Git & Docker
az vm run-command invoke \
    -g $rg \
    -n $vm \
    --command-id RunShellScript \
    --scripts "sudo apt-get update && sudo apt install -y git-all docker.io && sudo usermod -aG docker $admin && newgrp docker"

#Connecto to the Build VM
ssh $admin@$buildVmPublicIp

#Get the code
git clone https://github.com/whiteducksoftware/sample-mvc.git

#Build the API Container
cd sample-mvc/src/FredApi
docker build -t iamfred/mvcapi .

#Check Image is Created
docker images

#Spin up a Container from that image
docker run -d -p 8080:8080 iamfred/mvcapi -n apicontainer

#Test the container
echo $(wget -qO- http://localhost:8080/api/fredtext)

#build on ACR
az acr build --registry acrocp --image iamfred/mvcapi .

#create aks
#Portal

#NetworkPolicy
https://docs.microsoft.com/en-us/azure/aks/use-network-policies

#AKS Policy
https://docs.microsoft.com/en-us/azure/aks/use-azure-policy?toc=/azure/governance/policy/toc.json&bc=/azure/governance/policy/breadcrumb/toc.json

