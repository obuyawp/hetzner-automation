environment = "dev"

servers = {
  test_server = {
    name       = "dev-test-server"
    profile    = "cx23"
    location   = "hel1"
    image      = "ubuntu-22.04"
    private_ip = "10.0.1.10"
    volume_gb  = 0
    labels = {
      purpose = "testing"
    }
  }
  app_server = {
    name       = "dev-app-server"
    profile    = "cx33"
    location   = "fsn1"
    image      = "ubuntu-22.04"
    private_ip = "10.0.1.11"
    volume_gb  = 50
    labels = {
      purpose = "application"
    }
  }
}
