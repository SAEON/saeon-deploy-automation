# Server Setup & Application Deployment

This document outlines the standard operating procedure (SOP) for setting up Linux servers (dev/staging/prod) and deploying applications within SAEON's internal infrastructure. While application source code is publicly stored on GitHub, all deployments and hosting occur on our SAEON corporate servers.

---

## Overview

| Step | Script/Process          | Purpose                                                      |
| ---- | ----------------------- | ------------------------------------------------------------ |
| 1️  | `setup_saeon_server.sh`   | Prepares a new Linux server with Docker, Git, and NGINX installations |
| 2   | GitHub Self-Hosted Runner | Installs GitHub Actions runner on the server to trigger automated deployments |
| 3  | `deploy_saeon_apps.sh`    | Deploys an application from GitHub into SAEON server         |

---


## Step 1️: Server Setup (`setup_saeon_server.sh`)

> Run this script **once per server** (dev/test/prod) during provisioning.

### What does this script do:

- Installs essential packages: `git`, `curl`, `docker`, `docker-compose`, `nginx` packages
- Enables and starts Docker and NGINX services
- Adds current user (`$USER`) to the `docker` group
- Creates standard app folder structure under `/opt/apps/saeon/<dev|prod>`
- Ensures newly provisioned servers are consistent across environments 

### How to use the script:

Save the script in `/usr/local/bin` so that it is accessible system-wide. Then ensure execute permisions are assigned.  

```bash
chmod +x setup_saeon_server.sh
./setup_saeon_server.sh dev
```

### 📂 Example Outcome:

```
/opt/apps/saeon/prod/
  └── agri-census
```

## Step 2: Set Up GitHub Self-Hosted Runner

Perform these steps on every app server to enable GitHub Actions deployment from within server.


1. Go to the target GitHub repository (e.g., `https://github.com/SAEON/agri-census`)
2. Navigate to: `Settings → Actions → Runners → New self-hosted runner`
3. Choose your target server OS and copy the auto-generated setup commands


### Example:

```bash
$ mkdir actions-runner && cd actions-runner

$ curl -o actions-runner-linux-x64-2.327.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.327.1/actions-runner-linux-x64-2.327.1.tar.gz

$ ./config.sh --url https://github.com/SAEON/<repo-name> --token <generated-token>
```

### Install the action runnner as a service:

```bash
sudo ./svc.sh install
sud
```

This will ensure that the action runner is active at all times to receive GitHub Actions workflows for this server.

---


## Step 3: App Deployment (`deploy_saeon_apps.sh`)

Save the script in `/usr/local/bin` so that it is accessible system-wide. Then ensure execute permisions are assigned. Run this script from **within the appropriate SAEON internal network**. 


### What does this script do?:

- Verifies user is a member of the `saeon-devops` group
- Ensures the app folder exists under `/opt/apps/saeon/<dev|prod>/<app>`
- Clones the app's public GitHub repo if missing
- Pulls the latest changes from GitHub
- Builds and tags Docker image
- Runs `docker compose` to rebuild and restart container
- Reloads NGINX configuration
- Logs everything to `/opt/apps/saeon/<dev|prod>/logs/deploy-<app>-<timestamp>.log`


### Usage:

```bash
./deploy_saeon_apps.sh <env> <app-name>
```

#### Example:

```bash
./deploy_saeon_apps.sh prod agri-census
```

---

## Security Compliance

- Deployment scripts run entirely **from within SAEON network**
- No inbound GitHub-triggered deployments
- Internal servers only pull from GitHub, not pushed to
- Public GitHub is used for transparency, not automation
- SSH is disabled from the public internet

---

## Notes

- Logs are stored in: `/opt/apps/saeon/<dev|prod>/logs/`
- Docker images are tagged with timestamp + Git short hash for traceability

---

