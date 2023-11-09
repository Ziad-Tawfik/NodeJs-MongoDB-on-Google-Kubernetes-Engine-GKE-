# Highly Available NodeJs App Connected to MongoDB on Google Kubernetes Engine (GKE)

![Architecture](/Images/gcp-arch-jenkins-gke.png)

In this project I will deploy a simple Node.js web application **(stateless)** that interacts with a highly available MongoDB **(stateful)** replicated across **3 zones** and consisting of **1** primary and **2** secondaries.

Notes:
- Only the **Management VM (private)** will have access to internet through the **NAT**.
- The **GKE cluster (private)** will NOT have access to the internet.
- The **Management VM** will be used to manage the **GKE cluster** and **build/push** images to the **Artifact Registry**.
- All deployed images must be stored in Artifact Registry.
- Terraform will create infrastructure for **VPC** and **Jenkins** VM.
- Two Jenkins pipelines:
    - **1st pipeline** will use **terraform** to create the **Management VM** and **GKE**, then execute the **2nd pipeline**.
    - **2nd pipeline** will deploy **NodeJS** and **MongoDB** application on **GKE**.

----------
## Requirements
- **Terraform** is installed on your machine.
- GCP Account with **Billing Activated**.
- Service Account with **Project Owner Access** for **Jenkins VM** (Create it manually through GCP webUI).
![TF Service Account](/Images/SA.png)
- Enable **Service Usage API** in GCP for Terraform to be able to communicate with GCP || **[Service Usage API Activation Link](https://console.cloud.google.com/apis/api/serviceusage.googleapis.com)**.
- Create a Project in GCP and get its ID.

----------
## Steps
1. Clone this repo.

    ```Shell
    git clone https://github.com/Ziad-Tawfik/NodeJs-MongoDB-on-Google-Kubernetes-Engine-GKE-.git
    ```

2. Open **Jenkins-Infra-Terraform/dev-jenkins.tfvars** to replace the following variables's data with yours using sed command as mentioned below:   
    - **SA account ID** that you created before with owner role.
    - **Project ID**
    - **Optionally:** Jenkins VM Subnet's Region & Zone & CIDR.

    > ! Note that Jenkins VM, Management VM and GKE are all in the same VPC as per architecture above.

    ```Bash
    find /path/to/repo/folder -type f -exec sed -i 's/old-text/new-text/g' {} \;
    ```

3. Open **Terraform/dev.tfvars** to replace the following variables's data with yours using sed command as mentioned above:
    - **Project ID**
    - **Optionally:** Artifact Repo ID or Regions & Zones of Subnets & VMs.

    > ! Note that changing project id, artifact repo id, region or zone then you will have to modify other files and replace all the old names with the new ones using sed command as below or any other utility.

    > ! Note: You  can change the password of the **root login to the mongodb admin db** by modifying **Kube/mongokey.yaml**, and edit the mongodb-root-password with your password encoded in base64.
    
4. Push the project with your data to your repo.

5. Open Bash shell in the cloned **Jenkins-Infra-Terraform** folder.

6. Execute the below commands to let terraform build the infrastructure.
    ```Shell
    terraform init
    terraform apply --var-file dev-jenkins.tfvars
    ```
7. Review terraform plan and enter (y) if all is good.

8. Get Jenkins VM IP from GCP UI, and access this IP on web browser through port 8080.

    ![Jenkins VM](/Images/Jenkins-VM-Ext-IP.png)
    ![Jenkins 1](/Images/Jenkins1.png)

9. SSH into Jenkins VM through GCP SSH-in-Browser or using command line as below to get the admin password mentioned in the above path and walkthrough the installation process installing the suggested plugins and creating 

    ![Jenkins 2](/Images/Jenkins2.png)
    ![Jenkins 3](/Images/Jenkins3.png)
    ![Jenkins 4](/Images/Jenkins4.png)
    ![Jenkins 5](/Images/Jenkins5.png)

10. Create a pipeline with any name to create the rest of infrastructure (Management VM + GKE + Artifact Repo), choose pipeline script from SCM, add your github repo and change the name of jenkins file script to Infra-Jenkinsfile

    ![Jenkins 6](/Images/Jenkins6.png)
    ![Jenkins 7](/Images/Jenkins7.png)
    ![Jenkins 8](/Images/Jenkins8.png)

11. Create a second pipeline named **appDeployJob** with the same above steps but the script name is App-Jenkinsfile

    ![Jenkins 9](/Images/Jenkins9.png)
    ![Jenkins 10](/Images/Jenkins10.png)

12. Build the first pipeline and automatically after finishing it will start the second pipeline.

    ![Jenkins 11](/Images/Jenkins11.png)
    ![Jenkins 12](/Images/Jenkins12.png)
    ![Jenkins 13](/Images/Jenkins13.png)

8. Authenticate Google Cloud on your machine using account has admin access if you want to access the management vm from your terminal, 
    > Skip steps 6,7 if you are going to login to the management vm from GCP webUI.

    ```Shell
    gcloud init
    ```
8. After terraform creating the infrastructure, ssh into the management vm using below command with **your project id and vm zone** or from **GCP webUI**.
    ```Shell
    gcloud compute ssh --zone "vm-zone" "management-vm" --tunnel-through-iap --project "your-project-id"
    ```
8. Change directory to **simple-node-app** and execute the **run.sh** which will:
    - **Build** the **docker images** for nodejs, mongodb.
    - **Push** them to your **GCP artifact registery**.
    - **Create** all kubernetes deployment, statefulset, secret and services.

    > Note: You  can change the password of the **root login to the mongodb admin db** by modifying **mongokey.yaml** in this path **/simple-node-app/mongokey.yaml**, and edit the mongodb-root-password with your password encoded in base64 before executing the **run.sh**.

   ```Shell
    cd /simple-node-app;
    source run.sh
   ```

9. Check **Load Balancer External IP** and open it using web browser to check if there is a counter or not.
    ```Shell
    kubectl get svc
   ```
   ![Load Balancer External IP](/Images/External-ip.png)
   ![Counter in Browser](/Images/webbrowser1.png)

10. Each time you refresh the page or a new client accessed the IP will increase the number of visits.

11. We can verify the high availability of the infrastructure by taking down any pod of mongodb and check if the same IP has the same number of visits as before and increased by one.
    ```Shell
    kubectl delete pod mongo-0
    ```
    ![Before Deletion](/Images/pod1.png)
    ![After Deletion](/Images/pod2.png)
    ![Counter in Browser after deletion](/Images/webbrowser2.png)

12. To destroy the infrastructure, execute the below command.

    ```Shell
    terraform destroy --var-file dev.tfvars
    ```
----------
## What Happens Behind-The-Scenes❓
- **Terraform** will Create ***two service account***, one for the ***Management vm*** and the other one for the ***GKE cluster*** with the required permissions.

    ![Created SAs](/Images/Created_SA.png)

- Set up a **Virtual Private Cloud (VPC)**, configure **two Subnets**, establish a **NAT Gateway** for **outbound Internet** access, define a **Firewall Rule** to enable **IAP (Identity-Aware Proxy)** access to the management virtual machine, and create an **Artifact Registry** to store Docker images.

    ![VPC](/Images/VPC.png)
    ![Subnets](/Images/Subnets.png)
    ![Nat Gateway](/Images/Cloud-Nat.png)
    ![Firewall 1](/Images/allow-iap-firewall-1.png)
    ![Firewall 3](/Images/allow-iap-firewall-3.png)
    ![Artifact Registery](/Images/Artifact-Repo.png)

- Provision a **Management virtual machine**, deploy a **Google Kubernetes Engine (GKE)** cluster with a **node pool**, and associate **two service accounts** with them.

    ![Management VM](/Images/Management-VM.png)
    ![Attached SA to Management VM](/Images/ManagemetVM-Attached-SA.png)
    ![GKE Cluster](/Images/Kubernetes-Cluster.png)


- Startup script in the Management vm will clone this repo and create all required files in under ***/simple-node-app*** directory. 
    - 🌳 Files tree layout.

    ![VM /simple-node-app tree](/Images/Vm-Tree.png)

- Executing **run.sh** located in **/simple-node-app** in the **management vm**, the following actions are performed:

    - Authenticate Artifact Registery and GKE on the management vm.
    
    - Build docker images: **NodeJs**, **MongoDB**, **MongoDB Sidecar** (which facilitates automatic MongoDB configuration).

        ![Run 1](/Images/Run1.png)

    - Push the created images to the Artifact Registery.

        ![Run 2](/Images/Run2.png)

    - Apply all yaml files found under **/simple-node-app/kube** to the GKE

        ![Run 3](/Images/Run3.png)
        ![Run 4](/Images/Run4.png)
        ![Run 5](/Images/Run5.png)


----------

## :mage_man: Author
[Zyad M. Tawfik](https://www.linkedin.com/in/zyad-m-tawfik/)
