environment = "dev"

servers = {
  networks_general_prod = {
    name      = "Networks-general-prod"
    profile   = "cpx12"
    location  = "hel1"
    volume_gb = 0
    labels = {
      team         = "networks"
      requested_by = "zach"
    }
  }
}
