job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  reschedule {
    delay = "30s"
    delay_function = "constant"
    unlimited = true
  }

  # Documentation update_stanza
  # https://www.nomadproject.io/docs/job-specification/update.html
  update {
    max_parallel      = 1         # Number of allocations within a task group that can be updated at the same time
    health_check      = "checks"  # Allocation should be considered healthy when all of its tasks are running and their associated checks are healthy.
    min_healthy_time  = "10s"     # Minimum time the allocation must be in the healthy state before it is marked as healthy and unblocks further allocations from being updated. 
    healthy_deadline  = "5m"      # Specifies the deadline in which the allocation must be marked as healthy. Stops deployment of allocation if deadline is exceeded.
    progress_deadline = "10m"     # Specifies the deadline in which an allocation must be marked as healthy. Stops the deployment if deadline is exceeded.
    auto_revert       = true      # Specifies if the job should auto-revert to the last stable job on deployment failure.
    canary            = 0         # Specifies that changes to the job that would result in destructive updates should create the specified number of canaries without stopping any previous allocations.
    stagger           = "30s"     # Specifies the delay between migrating allocations off nodes marked for draining.
  }

  group "fail-service" {
    count = 3

    restart {
      interval = "10m"
      attempts = 2
      delay    = "15s"
      mode     = "fail"
    }

    task "fail-service" {
      driver = "docker"
      config {
        image = "thobe/fail_service:v0.0.12"
        port_map = {
          http = 8080
        }
      }

      service {
        name = "${TASK}"
        port = "http"
        tags = ["urlprefix-/fail-service strip=/fail-service"] # fabio
        check {
          name     = "fail_service health using http endpoint '/health'"
          port     = "http"
          type     = "http"
          path     = "/health"
          method   = "GET"
          interval = "10s"
          timeout  = "2s"
        }

        check_restart {
          limit = 3
          grace = "10s"
          ignore_warnings = false
        }
      }

      env {
        HEALTHY_IN    = 0,
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