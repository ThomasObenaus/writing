# How to set up a Container Orchestration System (COS)

In my previous post [How a Container Orchestration System could look like](https://link.medium.com/cRyTWm2N2S), I showed an architectural overview and discussed the most important components of such a system. It is based on [Nomad](https://www.nomadproject.io) as job scheduler, [Consul](https://www.consul.io) for service discovery and [fabio](https://fabiolb.net) for request routing and load balancing.

In this post I will describe step by step how to set up/ deploy this COS on an empty AWS account using [terraform](https://www.terraform.io).

_All steps described and scripts used in this post are tested with an ubuntu 16.04 but should also work on other linux based systems._

## Prerequisites

### AWS Account and Credentials Profile

The COS code is written in terraform using AWS services. Thus you need an AWS account to be able to deploy this system.
To create a new account you just have to follow the tutorial [Create and Activate an AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/).

Having an account you have to create AWS access keys using the AWS Web console:

1. Login into your new AWS account.
2. Create a new user for your account, by following this [tutorial](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html).
3. Create a new access key for this user, by following this [tutorial](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey).

When completing this steps, don't forget to actually download the keys. This is the only time you can do it. If you loose your keys you have to create a new one following the same steps.

![Access Keys](AccessKey.png)

The downloaded file `accessKeys.csv` contains the `Access key ID` and the `Secret access key`.

Now having the access key we can create an AWS profile. Such a profile is just a name referencing access keys and some options of an AWS account. Therefore you just have to create/ edit `~/.aws/credentials`.
In this file you just create a new section named `my_cos_account` pasting in the `Access key ID`, the `Secret access key` and save it.

```bash
[my_cos_account]
aws_access_key_id = PASTE HERE YOUR ACCESS KEY
aws_secret_access_key = PASTE HERE YOUR SECRET KEY
```

Now a profile named `my_cos_account` is available and will be used to directly create the AWS resources that are needed to set up the COS.

### Tools

Before we can really start to deploy the COS we have to install some essential tools.

1. **Terraform**: Is needed to create/ deploy AWS resources. Here **version 0.11.11** is used.

   - Download the binary from [Terraform Downloads](https://www.terraform.io/downloads.html).
   - Unzip and install it.

   ```bash
   cd ~/Downloads
   unzip terraform_0.11.11_linux_amd64.zip
   sudo mkdir -p /opt/terraform/0.11.11
   sudo mv terraform /opt/terraform/0.11.11
   cd /usr/bin
   sudo ln -s /opt/terraform/0.11.11/terraform terraform
   ```

   - Test it with `terraform --version`

2. **Nomad**: Is needed as CLI to be able to deploy services to the COS and show the status of the COS. Here **version 0.8.6** is used.

   - Download the binary from [Nomad Downloads](https://www.nomadproject.io/downloads.html)
   - Unzip and install it.

   ```bash
   cd ~/Downloads
   unzip nomad_0.8.6_linux_amd64.zip
   sudo mkdir -p /opt/nomad/0.8.6
   sudo mv nomad /opt/nomad/0.8.6
   cd /usr/bin
   sudo ln -s /opt/nomad/0.8.6/nomad nomad
   ```

- Test it with `nomad --version`

3. **Packer**: Is needed to bake (create) the AWS AMI that contains the nomad binary and is then actually used as image for the AWS EC2 instances that form the COS. Here **version 1.3.3** is used.

   - Download the binary from [Packer Downloads](https://www.packer.io/downloads.html)
   - Unzip and install it.

   ```bash
   cd ~/Downloads
   unzip packer_1.3.3_linux_amd64.zip
   sudo mkdir -p /opt/packer/1.3.3
   sudo mv packer /opt/packer/1.3.3
   cd /usr/bin
   sudo ln -s /opt/packer/1.3.3/packer packer
   ```

- Test it with `packer --version`

## Deployment

The whole setup consists of terraform code and is available at `https://github.com/MatthiasScholz/cos`.
This project is designed as a terraform module with a tailored API. It can be directly integrated into an existing infrastructure to add a COS to your infrastructure stack.
Additionally this project provides a self contained `root-example` that deploys beside the COS also a minimal networking infrastructure. We will use this example to deploy the COS.

Therefore the following steps have to be done:

1. Obtain the source code from github.
2. Build the Machine Image (AMI) for the EC2 instances.
3. Create an EC2 instance key pair.
4. Deploy the infrastructure and the COS.
5. Deploy fabio.
6. Deploy a sample service.

### Obtain the code

```bash
# Create work folder
mkdir ~/medium-cos/ && cd ~/medium-cos/

# Clone the code using tag v0.0.3
git clone --branch v0.0.3 https://github.com/MatthiasScholz/cos
```

### Build the Machine Image

In the end there has to be on some instances a server- and on some a client version of consul and nomad. The nice thing here is, that both, consul and nomad are shipped as a binary which supports the client and the server mode. They just have to be called with different parameters.
This leads to the nice situation that just one machine image has to baked. This image contains the nomad and the consul binary.

With this one AMI:

- Instances having consul running in server mode and no nomad running can be launched. These are representing the consul server nodes.
- Instances having consul running in client mode and nomad running in server mode can be launched. These are representing the nomad server nodes.
- Instances having consul running in client mode and nomad running in client mode can be launched. These are representing the nomad client nodes.

To build this AMI, first packer has to be supplied with the correct AWS credentials. As described at [Authentication Packer](https://www.packer.io/docs/builders/amazon.html#authentication) you can use static, environment variables or shared credentials.
These can be set in a shell by simply exporting the following parameters.

```bash
# environment variables
export AWS_ACCESS_KEY_ID=<your access key id>
export AWS_SECRET_ACCESS_KEY=<your secret key>
export AWS_DEFAULT_REGION=us-east-1
```

To build the AMI you just call:

```bash
cd ~/medium-cos/cos/modules/ami2
# build the
packer build -var 'aws_region=us-east-1' -var 'ami_regions=us-east-1' nomad-consul-docker.json
```

As a result you will get the id of the created AMI.

```bash
==> amazon-linux-ami2: Deleting temporary keypair...
Build 'amazon-linux-ami2' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-linux-ami2: AMIs were created:
us-east-1: ami-1234567890xyz
```

### Create an EC2 instance key pair

All instances of the COS can be accessed via ssh. Therefore during deployment an AWS instance key pair is needed.
The key to be created has to have the name `kp-us-east-1-playground-instancekey`. The key is referenced during deployment using exactly this name.

How to create a key pair is described at [Creating a Key Pair Using Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair).

### Deploy the infrastructure and the COS

To deploy the COS we will use the `examples/root-example` since it is self contained and builds not only the COS but also the needed networking infrastructure.

In this step we need the id of the AMI that was just created and the name of your AWS profile. In our example it is `ami-1234567890xyz` and `my_cos_account`.

```bash
cd ~/medium-cos/cos/examples/root-example
# Init terraform, download pugins and modules
terraform init

# generic terraform plan call
# terraform plan -out cos.plan -var deploy_profile=<your profile name> -var nomad_ami_id_servers=<your ami-id> -var nomad_ami_id_clients=<your ami-id>
terraform plan -out cos.plan -var deploy_profile=my_cos_account -var nomad_ami_id_servers=ami-1234567890xyz -var nomad_ami_id_clients=ami-1234567890xyz

# apply the planned changes, which means deploy the COS
terraform apply "cos.plan"
```

terraform plan -out cos.plan -var deploy_profile=my_cos_account -var nomad_ami_id_servers=ami-0b9a4b8a33ab8e025 -var nomad_ami_id_clients=ami-0b9a4b8a33ab8e025
