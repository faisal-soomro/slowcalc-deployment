# slowcalc-deployment
The purpose of this repository is to perform the fine tunings on the previously available version of `slow-calc` application at https://hub.docker.com/r/attensidev/slowcalc with tag `v2` and deploy it on AWS based infrastructure through terrafom, and finally deploy the application to serve the traffic with minimum error rates.


## Infrastructure Provisioning
### Pre-requisites:
- AWS Credentials for provisioning the resources
- awscli command line tool
- kubectl command line tool
- terraform command line tool

**NOTE:** The document provides the installation details for Ubuntu 20.04.

### Installing and Configuring AWS CLI tool
- Install AWS CLI using:
  ```bash
  sudo apt update
  sudo apt install awscli -y
  ```
- Verify the installation by running `aws`
- Configure the credentials for AWS by creating a credentials file at home directory as with the following details:
  ```bash
  # ~/.aws/credentials
  [default]
  aws_access_key_id = AWS_ACCESS_KEY
  aws_secret_access_key = AWS_SECRET_KEY
  ```

The same directory will be provided for terraform provider confiugrations to make things centralized and uniform.

### Installing kubectl
- The kubectl tool can be easily downloaded through snap using the following command: `sudo snap --classic install kubectl`
- Verify the installation by running `kubectl version`

The kubectl will be configured at later stage to communicate with kubernetes cluster.


### Terraform Installation and Initial Configurations
- Download the binary from https://www.terraform.io/downloads.html for terraform for the required verion. The downloaded binary for this project is shown in the steps below:
  ```bash
    wget https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip
    unzip terraform_0.15.4_linux_amd64.zip
    chmod +x terraform
    mv terraform /usr/local/bin/terraform
  ```
- Verify the instalation by running `terraform version`
- Create the S3 bucket in AWS console to be used by terraform as remote backend for maintaining state file. The configured bucket name for this project is `terraform-backend-01062021`, however it has to be unique name for the bucket, so change it in `terraform/terraform-configs.tf` in the terraform backend block.
- Go to the terraform directory with command `cd terraform`
- Run the initial commands after creating the bucket `terraform init` to complete the inititalization process.
- Take a good look at infrastructure changes to be made by running `terraform plan`
- Apply the changes through `terraform apply --auto-approve`
- At the completion, the AWS EKS based kubernetes cluster will be provsioned with the required resources.


### Configuring Kubernetes
- Configure the `kubeconfig` file, so the `kubectl` command can be used for creating kubernetes resources. Use the following command:
  ```bash
  aws eks --region=<EKS_REGION> update-kubeconfig --name=<EKSCLUSTER_NAME>
  ```
- This will configure the `kubeconfig` file which can be verified through `kubectl config get-contexts`

----------------------------

## Application Deployment