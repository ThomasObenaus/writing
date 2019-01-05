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
      }

      env {
        HEALTHY_IN    = -1, # Gets never healthy
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