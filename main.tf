terraform {
  cloud {
    organization = "obuya-infra"
    workspaces { name = "hetzner-automation" }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
/*
# 1. SSH KEY - Reading from your local file
resource "hcloud_ssh_key" "admin_key" {
  name       = "jenkins-provisioned-key"
  public_key = file("${path.module}/id_ed25519.pub")
}

# 2. PRIVATE NETWORK
resource "hcloud_network" "test_net" {
  name     = "automation-network"
  ip_range = "10.0.0.0/16"
}

# 3. SUBNET 
resource "hcloud_network_subnet" "helsinki_subnet" {
  network_id   = hcloud_network.test_net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# 4. SERVERS 
resource "hcloud_server" "nodes" {
  for_each    = var.server_list
  
  name        = each.key
  server_type = each.value.server_type
  location    = "hel1"
  image       = "ubuntu-22.04"
  ssh_keys = [hcloud_ssh_key.admin_key.id]

  network {
    network_id = hcloud_network.test_net.id
    ip         = each.value.ip_address
  }

  depends_on = [
    hcloud_network_subnet.helsinki_subnet
  ]
}
*/
