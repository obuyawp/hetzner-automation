provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" { sensitive = true }

resource "hcloud_network" "test_net" {
  name     = "automation-network"
  ip_range = "10.0.0.0/16"
}