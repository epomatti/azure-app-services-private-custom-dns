#!/bin/bash

workload="petzexpress"
acrName="acr$workload"
localImageTag="aks-go-app"
acrImageUrl="$acrName.azurecr.io/petzexpress-app:latest"

az acr login --name $acrName
docker build -f Dockerfile.amd64 -t $localImageTag .
docker tag $localImageTag $acrImageUrl
docker push $acrImageUrl
