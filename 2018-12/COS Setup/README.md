# How to set up a Container Orchestration System (COS)

In my previous post [How a Container Orchestration System could look like](https://link.medium.com/cRyTWm2N2S), I showed an architectural overview and discussed the most important components of such a system. It is based on [Nomad](https://www.nomadproject.io) as job scheduler, [Consul](https://www.consul.io) for service discovery and [fabio](https://fabiolb.net) for request routing and load balancing.

In this post I will describe step by step how to set up/ deploy this COS on an empty AWS account using [terraform](https://www.terraform.io).

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

### Tools

1. Terraform
2. Nomad
3. Packer
