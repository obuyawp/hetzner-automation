terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45" # It's good practice to lock the version
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# Your test resource
resource "hcloud_network" "test_net" {
  name     = "automation-network"
  ip_range = "10.0.0.0/16"
}