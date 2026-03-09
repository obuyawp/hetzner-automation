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
- `NETBIRD_SETUP_KEY` (type: Secret text)
- `TENABLE_KEY` (type: Secret text)

The Terraform plan/apply stages also use `server_admin_login` to generate a hashed password and bootstrap the admin user via cloud-init.

## 6. Pipeline flow

1. Terraform plan
2. Terraform apply
3. Post-provision over SSH (optional via Jenkins boolean parameters)
4. Publish inventory to Google Sheet webhook
