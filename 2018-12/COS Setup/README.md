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
