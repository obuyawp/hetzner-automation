environment = "dev"

servers = {
  hetzner_test = {
    name     = "dev-iac-server"
    profile  = "cpx22"
    location = "hel1"
    labels = {
      app  = "dev-iac"
      team = "infra"
    }
  }
}

