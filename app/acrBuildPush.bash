#!/bin/bash

acrName="$1"
localImageTag="contoso-app"
acrImageUrl="$acrName.azurecr.io/$localImageTag:latest"

az acr login --name $acrName
docker build -t $localImageTag .
docker tag $localImageTag $acrImageUrl
docker push $acrImageUrl
