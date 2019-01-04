# Nomad Job Template

1. minimal job file
   - curl over fabio is possible
2. minimal unhealthy job file
   - curl over fabio is NOT possible
   - will stay forever
   - gets unhealthy in consul
   - no automatic cleanup/ restart by nomad
3. Restarting unresponsive tasks: check_restart_unhealthy.nomad
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

4.
