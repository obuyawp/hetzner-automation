variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "server_list" {
  description = "Map of servers to create"
  type = map(object({
    server_type = string
    location    = string
    ip_address  = string
  }))
}