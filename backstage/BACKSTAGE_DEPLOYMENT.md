# Backstage Deployment on Existing Jenkins Host

This guide deploys Backstage on the same server as Jenkins using Docker Compose and Nginx.

## 1. Prerequisites

- Ubuntu/Debian host with sudo access
- Docker Engine + Docker Compose plugin (`docker compose`)
- Nginx installed
- DNS record for your Backstage domain (example: `backstage.example.com`) pointing to the server
- A built Backstage image in a registry (example: `ghcr.io/your-org/backstage:latest`)

## 2. Bootstrap deployment files

From repo root on the Jenkins host:

```bash
sudo ./backstage/deploy_backstage.sh bootstrap
```

This creates:

- `/opt/backstage/docker-compose.yml`
- `/opt/backstage/.env`
- `/opt/backstage/nginx-backstage.conf`
- `/opt/backstage/app-config.production.yaml`

If templates in this repo are updated later, refresh server copies with:

```bash
sudo ./backstage/deploy_backstage.sh sync
```

## 3. Configure runtime values

Edit:

```bash
sudo nano /opt/backstage/.env
```

Set at minimum:

- `BACKSTAGE_IMAGE` (your published Backstage image)
- `BACKSTAGE_BASE_URL` (public URL, e.g. `https://backstage.example.com`)
- `POSTGRES_PASSWORD` (strong password)
- `BACKEND_SECRET` (generate with `openssl rand -hex 32`)

## 4. Start Backstage stack

```bash
sudo ./backstage/deploy_backstage.sh up
sudo ./backstage/deploy_backstage.sh ps
```

Backstage listens on `127.0.0.1:7007` by default (not public directly).

## 5. Wire Nginx reverse proxy

```bash
sudo cp /opt/backstage/nginx-backstage.conf /etc/nginx/sites-available/backstage
sudo ln -s /etc/nginx/sites-available/backstage /etc/nginx/sites-enabled/backstage
sudo nginx -t
sudo systemctl reload nginx
```

Then add TLS (recommended):

```bash
sudo certbot --nginx -d backstage.example.com
```

## 6. Verify

- `curl -I http://127.0.0.1:7007` on the host
- Open `https://backstage.example.com`
- Check logs:

```bash
sudo ./backstage/deploy_backstage.sh logs
```

## 7. Operations

- Pull image updates: `sudo ./backstage/deploy_backstage.sh pull`
- Restart app: `sudo ./backstage/deploy_backstage.sh restart`
- Stop stack: `sudo ./backstage/deploy_backstage.sh down`
- Refresh compose/nginx templates from repo: `sudo ./backstage/deploy_backstage.sh sync`

## Notes

- Jenkins and Backstage can share one server as long as ports do not conflict.
- Keep Jenkins as executor initially; use Backstage for self-service UX and workflows.
- Production Backstage should use organization SSO and restricted scaffolder permissions.
