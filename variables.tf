variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "environment" {
  description = "Environment label applied to all infrastructure."
  type        = string
  default     = "dev"
}

variable "ssh_public_key_name" {
  description = "Name of the SSH key to register in Hetzner Cloud."
  type        = string
  default     = "jenkins-provisioned-key"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file."
  type        = string
  default     = "id_ed25519.pub"
}

variable "enable_ssh_key" {
  description = "Whether to register and attach an SSH key to new servers."
  type        = bool
  default     = false
}

variable "network_cidr" {
  description = "Private network CIDR for server communication."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR used inside the private network."
  type        = string
  default     = "10.0.1.0/24"
}

variable "network_zone" {
  description = "Hetzner network zone for the subnet."
  type        = string
  default     = "eu-central"
}

variable "admin_user" {
  description = "Optional bootstrap admin user. Use a pre-hashed password."
  type = object({
    enabled       = bool
    username      = string
    password_hash = string
  })
  default = {
    enabled       = false
    username      = ""
    password_hash = ""
  }
}

variable "server_profiles" {
  description = "Profile catalog for server types and cost metadata."
  type = map(object({
    server_type  = string
    category     = string
    architecture = string
    vcpu         = number
    ram_gb       = number
    disk_gb      = number
    traffic_tb   = number
    hourly_eur   = number
    monthly_eur  = number
  }))
}

variable "servers" {
  description = "Unified server inventory. Use stable keys and custom display names."
  type = map(object({
    name       = string
    profile    = string
    location   = optional(string, "hel1")
    image      = optional(string, "ubuntu-22.04")
    private_ip = optional(string)
    volume_gb  = optional(number, 0)
    labels     = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for _, cfg in var.servers : contains(keys(var.server_profiles), cfg.profile)])
    error_message = "Every server.profile must exist in server_profiles."
  }

  validation {
    condition     = alltrue([for _, cfg in var.servers : try(cfg.volume_gb, 0) >= 0])
    error_message = "volume_gb must be 0 or greater for every server."
  }
}
