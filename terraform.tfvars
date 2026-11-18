environment = "dev"

servers = {
  networks_general_prod = {
    name      = "Networks-general-prod"
    profile   = "cx23"
    volume_gb = 0
    labels = {
      team         = "networks"
      requested_by = "zach"
    }
  }
}
