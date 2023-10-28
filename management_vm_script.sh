#!/bin/bash

# Update the system
sudo apt-get upgrade && sudo apt-get update-y

# Install git
sudo apt-get install git
git clone https://github.com/Ziad-Tawfik/simple-node-app.git

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



#######################################################
## Kubernetes Part ##
#######################################################

# Create Kube Dir
mkdir -p /simple-node-app/kube

# Google cloud ssd storage class
sudo cat <<-EOF > /simple-node-app/kube/googlecloud_ssd.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
EOF


# Role Binding
sudo cat <<-EOF > /simple-node-app/kube/rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default-view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
EOF


# Load Balancer
sudo cat <<-EOF > /simple-node-app/kube/loadbalancer.yaml
# loadbalancer-service.yml
apiVersion: v1
kind: Service
metadata:
  name: loadbalancer-node
  labels:
    app: mynodejs
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
  selector:
    app: mynodejs
EOF


# nodejs
sudo cat <<-EOF > /simple-node-app/kube/nodejs-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mynodejs-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mynodejs
  template:
    metadata:
      name: mynodejs-pod
      labels:
        app: mynodejs
    spec:
      containers:
        - name: mynodejs-container
          image: us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mynode
          env:
            - name: DBuser
              value: "admin"
            - name: DBpass
              valueFrom:
                secretKeyRef:
                  name: mongo-key
                  key: mongodb-root-password
            - name: DBhosts
              value: "mongo-0.mongo.default.svc.cluster.local:27017,mongo-1.mongo.default.svc.cluster.local:27017,mongo-2.mongo.default.svc.cluster.local:27017"
          ports:
            - containerPort: 3000
EOF



# mongo-key
sudo cat <<-EOF > /simple-node-app/kube/mongokey.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongo-key
data:
  mongodb-root-password: cGFzc3dvcmQ=
EOF



# Mongo DB Statefulset
sudo cat <<-EOF > /simple-node-app/kube/mongodb-statefulset.yaml
#Create headless server
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  labels:
    name: mongo
spec:
  ports:
  - port: 27017
    targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: "mongo"
  replicas: 3
  selector:
    matchLabels:
      role: mongo
  template:
    metadata:
      labels:
        role: mongo
        environment: test
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongo
          args: ["--auth", "--bind_ip_all", "--replSet", "rs0", "--keyFile", "/etc/secrets-volume/mongodb-keyfile"]
          env:
            - name: "MONGO_INITDB_ROOT_USERNAME"
              value: "admin"
            - name: "MONGO_INITDB_ROOT_PASSWORD"
              valueFrom:
                secretKeyRef:
                  name: mongo-key
                  key: mongodb-root-password

          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-storage
              mountPath: /data/db

        - name: mongo-sidecar
          image: us-east4-docker.pkg.dev/gcp-project-402717/final-project-repository/mymongosidecar
          env:
            - name: MONGO_SIDECAR_POD_LABELS
              value: "role=mongo,environment=test"
            - name: KUBERNETES_MONGO_SERVICE_NAME
              value: "mongo"
            - name: MONGODB_USERNAME
              value: "admin"
            - name: MONGODB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-key
                  key: mongodb-root-password
            - name: MONGODB_DATABASE
              value: "admin"

  volumeClaimTemplates:
  - metadata:
      name: mongo-persistent-storage
      annotations:
        volume.beta.kubernetes.io/storage-class: "fast"
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
EOF


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
kubectl apply -f kube/googlecloud_ssd.yaml

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
echo "Create Mongokey in K8s"
echo "#########################"
kubectl apply -f kube/mongokey.yaml


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
echo "Create Role Binding in K8s"
echo "#########################"
kubectl apply -f kube/rolebinding.yaml


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
echo "Create Mongo Statefulset in K8s"
echo "#########################"
kubectl apply -f kube/mongodb-statefulset.yaml


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
kubectl apply -f kube/nodejs-deployment.yaml

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
echo "Create Load Balancer Service"
echo "#########################"
kubectl apply -f kube/loadbalancer.yaml

EOF


# Change run.sh permissions to be executable
sudo chmod 755 /simple-node-app/run.sh