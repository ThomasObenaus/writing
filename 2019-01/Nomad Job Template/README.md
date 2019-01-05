# A good Nomad Job Template

A Container Orchestration System (COS) adds application life cycle management, scheduling and placement based on available resources and connectivity features to your cloud system. It takes away the responsibility from you to take care for these tasks. Thus it is possible, instead of implementing the mentioned features in each of your services, to reduce the complexity in the components you have to develop.
Developing a cloud system the first goal is to satisfy your customers. Beside good quality of content, a responsive UI and a appealing design of the application the main goal is to have a resilient, fault tolerant and stable system. You want to get as close as possible to the 0-downtime label.

To get this, again, you can implement the needed parts in each of your components or you can take advantage of the qualities offered by the COS.
[Nomad](https://www.nomadproject.io) in particular covers three scenarios which would lead to potential downtime.
These are issues that can be mitigated or even solved using nomad:

1. Unresponsive Service - An already deployed and running version of the service gets unresponsive or unhealthy over time.
2. Dead Service - An already deployed and running version of the service gets unresponsive or unhealthy over time.
3. Dead Node - On a nomad client node something is completely broken. For example the docker daemon does not work any more.
4. Faulty Service Version - The latest commit introduces a bug that leads to instability of the service.

Of course, those four situations can be solved by an operator, who just restarts the service (1, 2), moves the service to a healthy node (3) and rolls back the service to a previously deployed version (4). But as we all know machines are better in doing repetitive tasks and are less error prone there. So lets make use of the features of the machine called nomad and automate this kind of self healing.

**In this post I want to present and discuss a nomad job definition that can be used as default template for most applications**. Of course there are parameters that have to be adjusted to your needs, but I want to line out what could be a good starting point in order to get a resilient application as described before.

## The Fail-Service

To test the resiliency features of nomad and develop the nomad job template incrementally a service whose stability can be influenced is needed. For this purpose I make use of the [Fail-Service](https://github.com/ThomasObenaus/dummy-services/tree/master/fail_service).

The fail-service is a small golang based service for testing purposes. The only feature it offers is getting healthy or unhealthy. The provided `/health` endpoint can be used to check the state. It reports 200_OK if the service is healthy or 504_GatewayTimeout otherwise.

The service state can be influenced via command line parameters or by sending a request to the `/sethealthy` or `/setunhealthy` endpoint.
Here are some examples:

```bash
# Service will stay healthy forever
./fail_service -healthy-for=-1

# Gets healthy in 10s, then after 20s it gets unhealthy. For 3s it stays unhealthy
# and gets healthy again to stay so for 20s. etc.
./fail_service -healthy-in=10 -healthy-for=20 -unhealthy-for=3

# Gets healthy in 10s, then after 20s it gets unhealthy and then stays unhealthy forever.
./fail_service -healthy-in=10 -healthy-for=20 -unhealthy-for=-1
```

To get the service it can be easily be build running `make build` and even better it can be pulled from Docker Hub via `docker pull thobe/fail_service:latest`. This makes it easy for us to use it directly in a nomad job file.

Which leads us to our first minimal nomad job file definition `minimal.nomad`.

```bash
job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  group "fail-service" {
    count = 1

    task "fail-service" {
      driver = "docker"
      config {
        image = "thobe/fail_service:v0.0.12"
        port_map = {
          http = 8080
        }
      }

      # Documentation for service stanza:
      # https://www.nomadproject.io/docs/job-specification/service.html
      service {
        name = "${TASK}"
        port = "http"
        tags = ["urlprefix-/fail-service strip=/fail-service"]
        check {
          name     = "fail_service health using http endpoint '/health'"
          port     = "http"
          type     = "http"
          path     = "/health"
          method   = "GET"
          interval = "10s"
          timeout  = "2s"
        }
      }

      env {
        HEALTHY_FOR    = -1, # Stays healthy forever
      }

      resources {
        cpu    = 100 # MHz
        memory = 256 # MB
        network {
          mbits = 10
          port "http" {}
        }
      }
    }
  }
}
```

While evolving the job file incrementally I'll just add the part that has changed regarding the previous one to keep the text in check. For each new configuration part the link to the official documentation is added inline.
In order to monitor the state of the service, nomad has to know how to obtain this information. This is specified in the `job > group > task > service > check{...}` section. There nomad shall call each 10s the `/health` endpoint of the service using the HTTP protocol and should treat the state as healthy if the service has responded within 2s.
The environment variable `HEALTHY_FOR` defined in `job > group > task > service > env {...}` is set to -1, which tells the fail-service to stay healthy forever.
With `tags = ["urlprefix-/fail-service strip=/fail-service"] # fabio` we specified that fabio shall route all requests that hit `/fail-service/*` shall be routed to the fail-service and that `/fail-service` shall be removed from the path. This is needed to ensure that the request hits the fail-service with `/health` and not with `/fail-service/health`, which the service does not implement.

## Platform for Testing

For being able to actually deploy the nomad job file that is developed here, a COS as described at [How a Container Orchestration System Could Look Like](https://medium.com/@obenaus.thomas/how-a-production-ready-container-orchestration-system-could-look-like-6f92b81a3319) is needed. You either can set one up in an AWS account, following the tutorial [How to Set Up a Container Orchestration System](https://medium.com/@obenaus.thomas/how-to-set-up-a-container-orchestration-system-cos-c5805790f0c1) or you can make use of nomads dev-mode.
How to use the dev-mode is described at [COS Project, devmode](https://github.com/MatthiasScholz/cos/tree/f/script_for_devmode/examples/devmode). There you simply have to call the provided script `./devmode <host-ip-addr> public-services`. This spins up a consul and a nomad instance and provides a nomad job file for fabio deployment.

Now we simply can deploy the first version by running `nomad run minimal.nomad`. Then with `watch -x curl -s http://\<cluster-address\>:9999/fail-service/health` you get back constantly a `200_OK` and `{"message":"Ok","ok":true}`.

## Adding Resilience

Now lets assume our service behaves somehow problematic - it gets unhealthy after 30s. This can be simulated by replacing the environment variable definition

```bash
env { HEALTHY_FOR    = -1 }
```

with

```bash
env {
  UNHEALTHY_FOR = -1,
  HEALTHY_FOR   = 30,
}
```

in the first job file and save it as `minimal_unhealthy.nomad`. With the deployment of this new version (`nomad run minimal_unhealthy.nomad`) you can see how the curl call stops returning messages. The reason for this is that fabio won't route any traffic to services that are unhealthy in the consul service catalog. This bad situation now will last forever since no one is here to stop or restart the faulty service.
Here nomad offers restart and rescheduling features. [Building Resilient Infrastructure with Nomad: Restarting tasks](https://www.hashicorp.com/blog/resilient-infrastructure-with-nomad-restarting-tasks) gives a nice explanation how failed or unresponsive jobs can be automatically restarted or even rescheduled on other nodes.

### Restart failed/ unresponsive Jobs

With the `job > group > task > service > check{...}` section, as part of the [service stanza](https://www.nomadproject.io/docs/job-specification/service.html)), nomad already knows how check the service health state. By adding the [check_restart stanza](https://www.nomadproject.io/docs/job-specification/check_restart.html) to the service definition, nomad knows when to kill a unresponsive service - how many failed health checks are enough to treat a service as unresponsive and "ready to be killed".
Then with the addition of the [restart stanza](https://www.nomadproject.io/docs/job-specification/restart.html) to the group definition you can control when and how nomad shall restart a killed service. This restart policy applies to services killed by nomad due to be unresponsive or exceeding memory limits and to those who just crashed.

The adjusted nomad job file `check_restart_unhealthy.nomad` now looks like and can be deployed via `nomad run check_restart_unhealthy.nomad`.

```bash
job "fail-service" {
  [..]
  group "fail-service" {
    count = 1

    # New restart stanza/ policy
    restart {
      interval = "10m"
      attempts = 2
      delay    = "15s"
      mode     = "fail"
    }
    # New restart stanza/ policy

    task "fail-service" {
      [..]
      service {
        [..]
        # New check_restart stanza
        check_restart {
          limit = 3
          grace = "10s"
          ignore_warnings = false
        }
        # New check_restart stanza
      [..]
```

# BACKLOG

1. minimal unhealthy job file
   - curl over fabio is NOT possible
   - will stay forever
   - gets unhealthy in consul
   - no automatic cleanup/ restart by nomad
2. Restarting unresponsive tasks: check_restart_unhealthy.nomad
   - show restart and migration life-cycle
   - explain potential reasons
   - explain check_restart stanza
   - describe the example (use the mysql example at https://www.nomadproject.io/docs/job-specification/check_restart.html)

#### Default behaviour without specifiying the restart_stanza

- describe restart_policy/ stanza

```bash
restart {
  interval = "1m"
  attempts = 2
  delay    = "15s"
  mode     = "fail"
}
```

- checks after 5s, then after 10s and again after 10s (intervall 10s, grace 5s, limit 3)
- then it gets killed
- then it gets restarted after 15s (delay 15s)
- this procedure is repeated 2 times
- then the service is considered as to be dead

```bash
01/04/19 16:07:34	Not Restarting	Exceeded allowed attempts 2 in interval 30m0s and mode is "fail"
01/04/19 16:07:30	Killed	Task successfully killed
01/04/19 16:07:29	Killing	Sent interrupt. Waiting 5s before force killing
01/04/19 16:07:29	Restart Signaled	healthcheck: check "fail_service health using http endpoint '/health'" unhealthy
01/04/19 16:07:03	Started	Task started by client

01/04/19 16:06:47	Restarting	Task restarting in 15.732809158s
01/04/19 16:06:43	Killed	Task successfully killed
01/04/19 16:06:43	Killing	Sent interrupt. Waiting 5s before force killing
01/04/19 16:06:43	Restart Signaled	healthcheck: check "fail_service health using http endpoint '/health'" unhealthy
01/04/19 16:06:17	Started	Task started by client

01/04/19 16:06:01	Restarting	Task restarting in 15.42486862s
01/04/19 16:05:57	Killed	Task successfully killed
01/04/19 16:05:56	Killing	Sent interrupt. Waiting 5s before force killing
01/04/19 16:05:56	Restart Signaled	healthcheck: check "fail_service health using http endpoint '/health'" unhealthy
01/04/19 16:05:30	Started	Task started by client
```

specify interval = "10m" # Carefully if it is too small the unhealthy service will be restared forever

4. Reschedule

- should avoid unlimited=false and attempts=x
- will leave job in failed state forever even a redeployment is not possible
- to fix you have to call nomad job stop fail-service
- and then nomad run fail-service.nomad
  --> create bug on nomad
  --> no auto revert supported for already deployed versions, can be checked by running the get_unhealthy.nomad

## Deployments

### Rolling

- auto_revert
- screenshot last stable

## Canary

- nomad deployment promote <deployment id>
- nomad deployment promote 6bd89b2d

## Blue Green

- canaray == count

## Migration

## Template as VSC, atom and emacs code snippet

- suggestion, please leave comments, ...
