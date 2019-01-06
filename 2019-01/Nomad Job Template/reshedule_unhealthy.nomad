job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  # Documentation of the reshedule_stanza
  # https://www.nomadproject.io/docs/job-specification/reschedule.html
  reschedule {
    delay = "30s"               # Duration to wait before attempting to reschedule a failed task.
    delay_function = "constant" # Function that is used to calculate subsequent reschedule delays.
    unlimited = true            # Enables unlimited reschedule attempts.
  }

  group "fail-service" {
    count = 1

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
        HEALTHY_IN    = -1,
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