#!/bin/bash

# Update the system
sudo apt-get upgrade && sudo apt-get update -y

# Install git
sudo apt-get install git
git clone https://github.com/Ziad-Tawfik/simple-node-app.git
git clone https://github.com/Ziad-Tawfik/NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-.git

# Install Docker
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install gcloud components
sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo
sudo echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
sudo apt-get update
sudo apt-get install kubectl google-cloud-cli-gke-gcloud-auth-plugin

# Login to artifact repo
sudo gcloud auth print-access-token | sudo docker login -u oauth2accesstoken --password-stdin https://us-east4-docker.pkg.dev

# Create Nodejs Dockerfile
sudo cat <<-EOF > /simple-node-app/Dockerfile.nodejs
# Build the application
FROM node:latest

WORKDIR /usr/src/app

# Copy package.json and package-lock.json separately to leverage Docker cache
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the application port
EXPOSE 3000

# Start Node.js application
CMD [ "node", "index.js" ]
EOF

# Create a key to authenticate the mongodb
sudo openssl rand -base64 741 > /simple-node-app/mongodb-keyfile
sudo chmod 0400 /simple-node-app/mongodb-keyfile

# Create Mongodb Dockerfile
sudo cat <<-EOF > /simple-node-app/Dockerfile.mongodb
# Start with the official MongoDB image
FROM mongo:5.0.15

# Copy an Auth key to the container
COPY mongodb-keyfile /etc/secrets-volume/mongodb-keyfile
RUN chmod 0400 /etc/secrets-volume/mongodb-keyfile && chown mongodb:mongodb /etc/secrets-volume/mongodb-keyfile 

# Expose MongoDB port
EXPOSE 27017 

# Set default command to run MongoDB
CMD ["mongod"]
EOF


# Create Side Car Container
sudo cat <<-EOF > /simple-node-app/Dockerfile.sidecar
# Side car image
FROM cvallance/mongo-k8s-sidecar:latest

# Start NPM
CMD ["npm", "start"]
EOF



###############################################

# Create a script to be executed in the vm
sudo cat <<-EOF > /simple-node-app/run.sh
echo ""
echo ""
echo ""
echo "#########################"
echo "Authenticating Docker, Kubernetes"
echo "#########################"
sudo gcloud auth print-access-token | sudo docker login -u oauth2accesstoken --password-stdin https://us-east4-docker.pkg.dev
gcloud container clusters get-credentials dev-cluster --region us-east4 --project gcp-project-402717

echo ""
echo ""
echo ""
echo "#########################"
echo "Building Docker Images"
echo "#########################"
cd /simple-node-app;
sudo docker build -t us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mynode -f Dockerfile.nodejs .;
sudo docker build -t us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongo -f Dockerfile.mongodb .;
sudo docker build -t us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongosidecar -f Dockerfile.sidecar .

echo ""
echo ""
echo ""
echo "#########################"
echo "Push Docker Images"
echo "#########################"
sudo docker push us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mynode;
sudo docker push us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongo;
sudo docker push us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongosidecar

echo ""
echo ""
echo ""
echo "#########################"
echo "Create SSD Storage Class in K8s"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/googlecloud_ssd.yaml

echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 10 Seconds"
echo "#########################"
sleep 10

echo ""
echo ""
echo ""
echo "#########################"
echo "Create Mongokey in K8s"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/mongokey.yaml


echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 10 Seconds"
echo "#########################"
sleep 10


echo ""
echo ""
echo ""
echo "#########################"
echo "Create Role Binding in K8s"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/rolebinding.yaml


echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 10 Seconds"
echo "#########################"
sleep 10


echo ""
echo ""
echo ""
echo "#########################"
echo "Create Mongo Statefulset in K8s"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/mongo-statefulset.yaml


echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 60 Seconds"
echo "#########################"
sleep 60

echo ""
echo ""
echo ""
echo "#########################"
echo "Create Nodejs Deployment"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/nodejs-deployment.yaml

echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 30 Seconds"
echo "#########################"
sleep 30


echo ""
echo ""
echo ""
echo "#########################"
echo "Create Load Balancer Service"
echo "#########################"
kubectl apply -f /NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-/Kube/loadbalancer.yaml

echo ""
echo ""
echo ""
echo "#########################"
echo "Wait 60 Seconds"
echo "#########################"
sleep 60

echo ""
echo ""
kubectl get svc

EOF


# Change run.sh permissions to be executable
sudo chmod 755 /simple-node-app/run.sh