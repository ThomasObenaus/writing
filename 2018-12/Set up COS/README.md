# How a production ready Container Orchestration System could look like

If you jumped on the container train and dockerized (or rockitized) your application components (microservices) you are on a good way for a scalable and resilient system.

The next questions to be answered are:

1. Scheduling - Where do these containers run?
2. Management - Who manages their lifecycle?
3. Service Discovery - How do they find each other?
4. Load Balancing - How to route requests?
5. Monitoring/ Logging - How can I see what is happening? What are they actually doing?

After some research one quickly finds systems like [kubernetes](https://kubernetes.io), [DC/OS](https://dcos.io), [AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html), [AWS EKS](https://aws.amazon.com/eks/) (managed kubernetes cluster), etc. Such systems are kind of orchesrtating the containers placement, communication and lifecycle. The so called **Container Orchestration Systems** are responsible to manage containers and to abstract away the actual location they are running on.

All of them have their advantages, disadvantages and of course a different feature set. For example DC/OS has really a big feature set but it is very hard to set up a production ready DC/OS cluster. Using kubernetes on Google Cloud is a good idea but as soon as you want to spin it up in an AWS environment you will have a hard time.
These problems have vanished with AWS EKS. But since this service is relatively new, important features are missing. Additionally, and even more important, with AWS EKS you loose the option to run a hybrid multi IaaS provider platform. With the abstraction you gained by using containers there is lot of potential in offloading components on cheaper platforms like [Microsoft Azure](https://azure.microsoft.com/en-us/) or even regional data-centers. Thus looking at the costs it is a good idea to keep this option.

## Nomad as Core Component

After looking at the mentioned Container Orchestration Systems there is one not to forget - it is named [Nomad](https://www.nomadproject.io). **Nomad is a scheduler of applications and services** nothing more, nothing less. Nomad can't compete with the featureset provided by kubernetes or DC/OS. But all the important features for managing and running services are available. It does "just" one job but does it very well.
Other features like service discovery, load-balancing, secret management, monitoring and logging are available open source and can be added easily.

Nomad is developed by [Hashicorp](https://www.hashicorp.com), a company focusing on Cloud Infrastructure Automation. Having the big picture in mind the hashicorp developers exactly know what are the important things and how these can be implemented in powerfull components and tools. Beside nomad they provide [Consul](https://www.consul.io) (for service discovery and connectivity), [Vault](https://www.hashicorp.com/products/vault/) (for secretmangament) and [terraform](https://www.terraform.io) (a tool for provisoning infrastructure). All of them integrate very well with nomad, adding some of the missing features, like service discovery to the Container Orchestration System to be set up.

To summarize - the most usefull features that lead to the decision for nomad are:

- Complexity - Nomad is easy to understand and thus to set up and maintain.
- Good Job - Nomad is a highly scalable and fast scheduler using an optimistic approach.
- Container Support - Docker, rocket, simple binaries/ excecutables can be scheduled.
- Cloud Provider Agnostic - Hybrid, multis IaaS provider cloud is possible.
- Extensability - Very good integration in hasicorp tools. Thus the missing core features can be added in a easy and natural way.

## Architectural Overview
