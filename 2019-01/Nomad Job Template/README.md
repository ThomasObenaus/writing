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
4.
