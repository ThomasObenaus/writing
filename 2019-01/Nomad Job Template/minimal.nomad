job "fail-service" {
  datacenters = ["public-services"]

  type = "service"

  group "fail-service" {
    count = 1

    task "fail-service" {
      driver = "docker"
      config {
        image = "thobe/fail_service:v0.0.12"
        port_map = {
          http = 8080
        }
      }

      # Documentation for service stanza:
      # https://www.nomadproject.io/docs/job-specification/service.html
      service {
        name = "${TASK}"  # Specifies the name this service will be advertised as in Consul
        port = "http"     # Specifies the port to advertise for this service
        tags = ["urlprefix-/fail-service strip=/fail-service"] # fabio
        check {
          name     = "fail_service health using http endpoint '/health'"  # Name of the health check
          port     = "http"                                               # Specifies the label of the port on which the check will be performed.
          type     = "http"                                               # This indicates the check types supported by Nomad. Valid options are grpc, http, script, and tcp. 
          path     = "/health"                                            # Specifies the path of the HTTP endpoint which Consul will query to query the health of a service.
          method   = "GET"                                                # Method used for http checks
          interval = "10s"                                                # Specifies the frequency of the health checks that Consul will perform. 
          timeout  = "2s"                                                 # Specifies how long Consul will wait for a health check query to succeed.
        }
      }

      env {
        HEALTHY_FOR    = -1, # Stays healthy forever
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