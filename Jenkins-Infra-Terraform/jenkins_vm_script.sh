#!/bin/bash

# Update the system
sudo apt-get upgrade && sudo apt-get update -y

# Install dependencies
sudo apt-get install -y apt-transport-https ca-certificates gnupg \
 curl sudo unzip software-properties-common gnupg2 wget

# Install git
sudo apt-get install -y git

# Install Terraform
sudo wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
sudo unzip terraform_1.5.7_linux_amd64.zip -d /usr/local/bin/ 
sudo rm terraform_1.5.7_linux_amd64.zip

# Install Java
sudo apt install -y openjdk-17-jre-headless

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
sudo echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# Install gcloud components
sudo echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
sudo apt-get update -y
sudo apt-get install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin
