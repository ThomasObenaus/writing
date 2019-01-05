job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  group "fail-service" {
    count = 3

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
        check {
          name     = "fail_service health using http endpoint '/health'"
          port     = "http"
          type     = "http"
          path     = "/health"
          method   = "GET"
          interval = "10s"
          timeout  = "2s"
        }

        # Documentation of check_restart_stanza
        # https://www.nomadproject.io/docs/job-specification/check_restart.html
        check_restart {
          limit = 3               # Restart task when a health check has failed limit times.
          grace = "10s"            # Duration to wait after a task starts or restarts before checking its health.
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