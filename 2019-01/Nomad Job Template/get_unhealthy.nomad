job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  reschedule {
    delay = "30s"
    attempts = 2
    delay_function = "constant"
    interval = "20m"
    unlimited = false
  }

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = true
    canary            = 0
    stagger           = "30s"
  }

  group "fail-service" {
    count = 3

    restart {
      interval = "10m"
      attempts = 1
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
          limit = 1
          grace = "10s"
          ignore_warnings = false
        }
      }

      env {
        HEALTHY_IN    = 0,
        UNHEALTHY_FOR = -1,
        HEALTHY_FOR   = 30,
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