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

locals {
  resolved_servers = {
    for id, cfg in var.servers : id => merge(cfg, {
      server_type = var.server_profiles[cfg.profile].server_type
      location    = try(cfg.location, "hel1")
      image       = try(cfg.image, "ubuntu-22.04")
      volume_gb   = try(cfg.volume_gb, 0)
      labels = merge(
        {
          environment = var.environment
          managed_by  = "terraform"
          profile     = cfg.profile
        },
        try(cfg.labels, {})
      )
    })
  }

  servers_with_volume = {
    for id, cfg in local.resolved_servers : id => cfg
    if cfg.volume_gb > 0
  }
}

resource "hcloud_ssh_key" "admin_key" {
  count = var.enable_ssh_key ? 1 : 0

  name       = var.ssh_public_key_name
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_network" "automation" {
  name     = "${var.environment}-automation-network"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "automation_subnet" {
  network_id   = hcloud_network.automation.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_cidr
}

resource "hcloud_server" "nodes" {
  for_each = local.resolved_servers

  name        = each.value.name
  server_type = each.value.server_type
  location    = each.value.location
  image       = each.value.image
  labels      = each.value.labels
  ssh_keys    = var.enable_ssh_key ? [hcloud_ssh_key.admin_key[0].id] : null

  dynamic "network" {
    for_each = [
      {
        network_id = hcloud_network.automation.id
        ip         = try(each.value.private_ip, null)
      }
    ]
    content {
      network_id = network.value.network_id
      ip         = network.value.ip
    }
  }

  user_data = var.admin_user.enabled ? templatefile(
    "${path.module}/templates/cloud-init-admin-user.yaml.tftpl",
    {
      username      = var.admin_user.username
      password_hash = var.admin_user.password_hash
    }
  ) : null

  depends_on = [hcloud_network_subnet.automation_subnet]
}

resource "hcloud_volume" "server_data" {
  for_each = local.servers_with_volume

  name     = "${each.value.name}-data"
  size     = each.value.volume_gb
  location = each.value.location
  format   = "ext4"
  labels = merge(each.value.labels, {
    role = "data"
  })
}

resource "hcloud_volume_attachment" "server_data_attachment" {
  for_each = local.servers_with_volume

  server_id = hcloud_server.nodes[each.key].id
  volume_id = hcloud_volume.server_data[each.key].id
  automount = true
}

output "inventory_servers" {
  value = [
    for id in sort(keys(hcloud_server.nodes)) : {
      server_id   = id
      name        = hcloud_server.nodes[id].name
      public_ip   = hcloud_server.nodes[id].ipv4_address
      private_ip  = try(hcloud_server.nodes[id].network[0].ip, null)
      environment = var.environment
      server_type = local.resolved_servers[id].server_type
      status      = hcloud_server.nodes[id].status
      volume_gb   = try(local.resolved_servers[id].volume_gb, 0)
      created_at  = try(hcloud_server.nodes[id].created, null)
    }
  ]
}

output "server_public_ips_csv" {
  value = join(",", [
    for id in sort(keys(hcloud_server.nodes)) : hcloud_server.nodes[id].ipv4_address
  ])
}
