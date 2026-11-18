# Hetzner Provisioning and Operations

## 1. One-file inventory updates

Update servers in `terraform.tfvars`:

```hcl
servers = {
  dataiku_primary = {
    name       = "prod-dataiku-server"
    profile    = "ccx23"
    location   = "hel1"
    private_ip = "10.0.1.5"
    volume_gb  = 100
    labels = {
      app = "dataiku"
    }
  }
}
```

- `profile` must exist in `server_profiles.auto.tfvars.json`.
- `name` supports custom names.
- `servers` map key (`dataiku_primary`) is the stable Terraform identity.

### Quick profile table (admin view)

Instead of opening the long JSON directly, render a table:

```bash
./scripts/list_server_profiles.sh
```

Optional Markdown output (for tickets/docs):

```bash
./scripts/list_server_profiles.sh --markdown
```

## 2. Provisioning outputs for inventory

After `terraform apply`, run:

```bash
terraform output -json inventory_servers
```

This output is posted by Jenkins to the Google Apps Script webhook.

## 3. Operations scripts

Scripts are in `scripts/ops/`:

- `create_admin_user.sh`
- `install_azure_deployment_agent.sh`
- `configure_zabbix.sh`
- `install_netbird.sh`
- `install_wazuh.sh`
- `install_tenable.sh`
- `run_hardening.sh`
- `run_post_provision.sh`
- `CIS_Ubuntu_Hardening_Benchmarks.sh` (paste your full hardening script here)

You can run all enabled operations:

```bash
sudo RUN_AZURE_AGENT=true RUN_WAZUH=true RUN_TENABLE=true ./scripts/ops/run_post_provision.sh
```

Run only hardening:

```bash
sudo ./scripts/ops/run_hardening.sh
```

## 4. Required secrets

Set secrets in Jenkins credentials or secure env injection:

- `TF_VAR_hcloud_token`
- `AZP_TOKEN`
- `NETBIRD_SETUP_KEY`
- `TENABLE_KEY`
- `server_admin_login` (type: Username with password)

## 5. Jenkins credential IDs for post-provision stage

The pipeline stage `Post-Provision Configure Servers` expects:

- `server_admin_login` (type: Username with password)
- `AZP_TOKEN` (type: Secret text, required when `RUN_AZURE_AGENT=true`)
- `NETBIRD_SETUP_KEY` (type: Secret text)
- `TENABLE_KEY` (type: Secret text)

The Terraform plan/apply stages also use `server_admin_login` to generate a hashed password and bootstrap the admin user via cloud-init.

## 6. Pipeline flow

1. Terraform plan
2. Terraform apply
3. Post-provision over SSH (optional via Jenkins boolean parameters)
4. Publish inventory to Google Sheet webhook

## 7. Hetzner project and shared state

- The Hetzner **project is chosen only by the API token** in the Jenkins credential `hcloud_token`. Nothing in the repo selects a project.
- `hcloud_token` belongs to the **ITO-TRAINING** project. Every server this pipeline creates lands there.
- State lives in HCP Terraform: org `obuya-infra`, workspace `hetzner-automation`.
- The shared private network `dev-automation-network` (id `12013423`, `10.0.1.0/24`) is in ITO-TRAINING and is reused by every server. It survives removing all servers.
- The `environment` variable (`dev`) labels every resource and names that network. It does not control the project.
- Branch `dev` is the working branch. `main` is an old layout (`server_list`, no ops scripts or profile catalog); do not use it as a reference.
- To deploy into a different Hetzner project you need its own API token, its own Jenkins credential and its own HCP workspace. Swapping the token inside the existing workspace would make Terraform look for network `12013423` in the new project and lose track of the ITO-TRAINING one.

## 8. Profile catalog notes

- `server_profiles.auto.tfvars.json` drives both validation and the Slack cost estimate, so keep prices current.
- The `cpx` entries were refreshed from the Hetzner Console (`cpx02`, `cpx12`, `cpx22`, `cpx32`, `cpx42`, `cpx52`, `cpx62`). The `cx`, `cax` and `ccx` entries have not been refreshed and may be out of date.
- Availability varies by location. In `hel1` the Intel `cx` types (`cx23`, `cx33`, ...) were not offered; only `cpx` types were. Check the Console create-server screen before choosing a profile.

## 9. Worked example: Networks-general-prod

```hcl
servers = {
  networks_general_prod = {
    name      = "Networks-general-prod"
    profile   = "cpx12"      # 1 vCPU, 2 GB, 40 GB, EUR 9.49/mo
    location  = "hel1"
    volume_gb = 0
    labels = {
      team         = "networks"
      requested_by = "zach"
    }
  }
}
```

- `networks_general_prod` is the stable Terraform key. `name` is what Hetzner shows. Do not rename the key after creation or the server is destroyed and recreated.
- It is created in ITO-TRAINING and carries the label `environment = dev`, even though the name says prod.

## 10. Troubleshooting

- `Error: error during placement (resource_unavailable)`: Hetzner has no capacity for that server type in that location. Nothing is created. Choose a different profile or location (any of `hel1`, `fsn1`, `nbg1` works with the existing `eu-central` network).
- A docs-only push still triggers the Jenkins job and a new plan. If a server is not yet created, that plan will ask for approval again. Push docs after the apply finishes.
- Jenkins prints the admin password hash and username in the console log (shell trace). The plain password is masked, the hash is not. Treat the build log as sensitive.
