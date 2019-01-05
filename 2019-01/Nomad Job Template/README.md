# A good Nomad Job Template

A Container Orchestration System (COS) adds application life cycle management, scheduling and placement based on available resources and connectivity features to your cloud system. It takes away the responsibility from you to take care for these tasks. Thus it is possible instead of implementing the mentioned features in each of your services to reduce the complexity in the components you have to develop.
Developing a cloud system the first goal is to satisfy your customers. Beside good quality of content, a responsive UI and a appealing design of the application the main goal is to have a resilient, fault tolerant and stable system. You want to get as close as possible to the 0-downtime label.

To get this, again, you can implement the needed parts in each of your components or you can take advantage of the qualities offered by the COS.
[Nomad](https://www.nomadproject.io) in particular covers three scenarios which would lead to potential downtime.
These are issues that can be mitigated or even solved using nomad:

1. Dead Service - An already deployed and running version of the service gets unresponsive or unhealthy over time.
2. Dead Node - On a nomad client node something is completely broken. For example the docker daemon does not work any more.
3. Faulty Service Version - The latest commit introduces a bug that leads to instability of the service.

In this post I want to present and discuss a nomad job definition that can be used as default template for most applications.

## Intro of Fail-Service

1. minimal job file
   - curl over fabio is possible

## Resilience

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

(optional)
