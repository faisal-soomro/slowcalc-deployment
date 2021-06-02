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
To deploy the application, use the kubernetes resources, i.e deployment and service, and the resource definitions are available in `kubernetes-resources` directory.

### Prerequisite
- Apache Server Benchmarking Tool (ab)

Install ab in using the following commands:
```bash
sudo apt update
sudo apt install apache2-utils -y
```

### Testing slowcalc:v2 deployment

- Test the slow-calc pod first to figure out the slowness in the application:
  ```bash
  cd kubernetes-resources
  kubectl apply -f slow-calc-pod.yaml
  kubectl apply -f slow-calc-svc.yaml
  ```

- Verify the application accessibility through the service external endpoint and can be checked through `kubectl get svc`. The External-IP field provided in our case is `a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com`.The following output will be provided:
  ```bash
  NAME         TYPE        CLUSTER-IP     EXTERNAL-IP                                                                  PORT(S)        AGE
  kubernetes   ClusterIP   10.96.0.1      <none>                                                                       443/TCP        34h
  slow-calc    NodePort    10.100.108.6   a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com        80:31047/TCP   33h
  ```

- Verify the access through curl command as follows:
  ```bash
  curl http://a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com/health

  # OUTPUT
  I'm still alive!
  Will die in 124 seconds.
  ```

- Test the POST method with apache bench using the 100 concurrent requests with total of 1000 of requests with the following command:
  ```bash
  cd ../container_data
  ab -n 1000 -c 100 -p curl_data a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com/calc

  # RESULTS
  This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
  Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
  Licensed to The Apache Software Foundation, http://www.apache.org/

  Benchmarking a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com (be patient)
  apr_pollset_poll: The timeout specified has expired (70007)
  Total of 10 requests completed
  ```

- The pods started to crash in the deployment or due to high load.

- The server also died after 124 seconds, giving output `She's dead, Jim!`


### Fixing the bugs and creating slowcalc:v2.1 deployment
- The new version of slowcalc image has been created by fixing codebase for slowness through reverse engineering and the code is available in `container_data` directory.

- Create the new docker image and push it to the dockerhub for using it for the deployments. The `faisalsoomro` is the dockerhub username used in this case and the steps are as follows:
  ```bash
  cd container_data
  docker image build -t faisalsoomro/slowcalc:v2.1 .
  docker push faisalsoomro/slowcalc:v2.1
  ```

- Test the new version of slow-calc through deployment this time and apply the following changes:
  ```bash
  cd ../kubernetes-resources
  kubectl delete -f slow-calc-pod.yaml
  kubectl apply -f slow-calc-deploy.yaml
  ```

- The service is not required to be redeployed and the external endpoint remains the same i.e `a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com`.

- Verify the access through curl command as follows:
  ```bash
  curl http://a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com/health

  # OUTPUT
  I'm still alive!
  ```

- Test the POST method with apache bench using the 100 concurrent requests with total of 1000 of requests with the following command:
  ```bash
  cd ../container_data
  ab -n 1000 -c 100 -p curl_data a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com/calc

  # RESULTS
  This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
  Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
  Licensed to The Apache Software Foundation, http://www.apache.org/

  Benchmarking a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com (be patient)
  Completed 100 requests
  Completed 200 requests
  Completed 300 requests
  Completed 400 requests
  Completed 500 requests
  Completed 600 requests
  Completed 700 requests
  Completed 800 requests
  Completed 900 requests
  Completed 1000 requests
  Finished 1000 requests


  Server Software:
  Server Hostname:        a3f694ef85d10431c9e168ca713eb328-71825499.us-east-2.elb.amazonaws.com
  Server Port:            80

  Document Path:          /calc
  Document Length:        11 bytes

  Concurrency Level:      100
  Time taken for tests:   15.973 seconds
  Complete requests:      1000
  Failed requests:        0
  Total transferred:      87000 bytes
  Total body sent:        191000
  HTML transferred:       11000 bytes
  Requests per second:    62.60 [#/sec] (mean)
  Time per request:       1597.346 [ms] (mean)
  Time per request:       15.973 [ms] (mean, across all concurrent requests)
  Transfer rate:          5.32 [Kbytes/sec] received
                        11.68 kb/s sent
                        17.00 kb/s total

  Connection Times (ms)
                min  mean[+/-sd] median   max
  Connect:      115  128  17.4    124     316
  Processing:   352 1247 323.8   1219    3584
  Waiting:      352 1245 322.9   1218    3584
  Total:        473 1376 324.8   1352    3706

  Percentage of the requests served within a certain time (ms)
    50%   1352
    66%   1485
    75%   1569
    80%   1631
    90%   1797
    95%   1925
    98%   2024
    99%   2170
   100%   3706 (longest request)
  ```

- The application was able to serve the requests this time and the server didn't die this time with any timeout duration.