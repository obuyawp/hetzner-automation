environment = "dev"

servers = {
  test_server = {
    name     = "demo-server-test"
    profile  = "cpx22"
    location = "hel1"
    labels = {
      app  = "demo-infra"
      team = "infra"
    }
  }
}

