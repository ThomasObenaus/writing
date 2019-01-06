job "{{service_name}}" {
  datacenters = [{{list_of_datacenters}}]

  type = "service"

  reschedule {
    delay = "30s"
    delay_function = "constant"
    unlimited = true
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

  group "{{service_name}}" {
    count = {{count}}

    restart {
      interval = "10m"
      attempts = 2
      delay    = "15s"
      mode     = "fail"
    }

    task "{{service_name}}" {
      driver = "docker"
      config {
        image = "{{docker_image}}"
        port_map = {
          http = {{exposed_port_for_health_check}}
        }
      }

      service {
        name = "{{service_name}}"
        port = "http"
        tags = ["urlprefix-/{{service_name}} strip=/{{service_name}}"] # fabio
        check {
          name     = "{{service_name}} health using http endpoint '/health'"
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