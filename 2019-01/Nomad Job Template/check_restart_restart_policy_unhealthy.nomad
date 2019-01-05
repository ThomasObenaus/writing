job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  group "fail-service" {
    count = 3

    # Documentation of restart_stanza
    # https://www.nomadproject.io/docs/job-specification/restart.html
    restart {
      interval = "10m"  # The duration which begins when the first task starts and ensures that only attempts number of restarts happens within it. 
      attempts = 2      # The number of restarts allowed in the configured interval.
      delay    = "15s"  # Specifies the duration to wait before restarting a task. 
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
        tags = ["urlprefix-/fail-service"] # fabio
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