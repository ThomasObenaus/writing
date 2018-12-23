# Set up a production ready Container Orchestration System

If you jumped on the container train and dockerized (or rockitized) your application components (microservices) you are on a good way for a scalable and resilient system.

The next questions to be answered are:

1. Where do these containers run?
2. Who manages their lifecycle?
3. How do they find each other?
4. How can I see what is happening? What are they actually doing?

After some research one quickly finds systems like [kubernetes](https://kubernetes.io), [DC/OS](https://dcos.io), [AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html), [AWS EKS](https://aws.amazon.com/eks/) (managed kubernetes cluster), etc. Such systems are kind of orchesrtating the containers placement, communication and lifecycle. The so called **Container Orchestration Systems** are responsible to manage containers and to abstract away the actual location they are running on.

All of them have their advantages, disadvantages and of course a different feature set. For example DC/OS has really a big feature set but it is very hard to set up a production ready DC/OS cluster. Using kubernetes on Google Cloud is a good idea but as soon as you want to spin it up in an AWS environment you will have a hard time.
These problems have vanished with AWS EKS. But since this service is relatively new, important features are missing. Additionally, and even more important, with AWS EKS you loose the option to run a hybrid multi IaaS provider platform. With the abstraction you gained by using containers there is lot of potential in offloading components on cheaper platforms like [Microsoft Azure](https://azure.microsoft.com/en-us/) or even regional data-centers. Thus looking at the costs it is a good idea to keep this option.

## Nomad as Core Component

After looking at the mentioned Container Orchestration Systems there is one more not to forget - it is named [Nomad](https://www.nomadproject.io). **Nomad is a scheduler of applications and services** nothing more, nothing less. Nomad can't compete with the featureset provided by kubernetes or DC/OS. But all the important features for managing and running services are available. It does "just" one job but does it right.
Other features like service discovery, load-balancing, secret management, monitoring and logging are available and can be integrated easily.
