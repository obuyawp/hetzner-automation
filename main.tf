terraform {
  # 1. This handles your Remote State "Memory"
  cloud {
    organization = "obuya-infra"
    workspaces {
      name = "hetzner-automation"
    }
  }

  # 2. This tells Terraform where to download the Hetzner plugin
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# Your test resource
# resource "hcloud_network" "test_net" {
#  name     = "automation-network"
#  ip_range = "10.0.0.0/16"
# }