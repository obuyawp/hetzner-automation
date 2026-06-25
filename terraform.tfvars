environment = "dev"

servers = {
    dataiku_primary = {
    name       = "infra-test-server"
    profile    = "ccx23"
    location   = "hel1"
    private_ip = "10.0.1.5"
    volume_gb  = 10
    labels = {
      app  = "dataiku"
      team = "platform"
    }
  }
}
