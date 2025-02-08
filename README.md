```
# Dockerized Pterodactyl Panel & Wings with Traefik

<p align="center">
  <img width="500" src="https://raw.githubusercontent.com/BeefBytes/Assets/master/Other/container_illustration/v2/dockerized_pterodactyl.png" alt="Dockerized Pterodactyl">
</p>

## Overview

This repository provides a streamlined guide for deploying the **Pterodactyl Panel** and **Wings** using Docker containers with **Traefik** as a reverse proxy. The setup has been rigorously tested in production, using official images and compose files from Pterodactyl with minor additions to integrate Traefik.

> **Note:** This guide assumes you have two separate servers:
> - **Panel Server:** Hosts the web interface (Pterodactyl Panel).
> - **Wings Server:** Hosts the game servers (Pterodactyl Wings).

---

## Table of Contents

- [Requirements](#requirements)
- [DNS Configuration](#dns-configuration)
- [Installation](#installation)
  - [Quick Start (Recommended)](#quick-start-recommended)
  - [Manual Installation](#manual-installation)
    - [1. Set Up Traefik (Both Servers)](#1-set-up-traefik-both-servers)
    - [2. Set Up the Panel (Panel Server Only)](#2-set-up-the-panel-panel-server-only)
    - [3. Set Up Wings (Wings Server Only)](#3-set-up-wings-wings-server-only)
- [Security Recommendations](#security-recommendations)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

---

## Requirements

- **Servers:** Two Linux servers (one for the Panel and one for Wings)
- **Domain:** Ability to create subdomains
- **Software:**
  - [Docker (v20.10+)](https://docs.docker.com/engine/install/ubuntu/)
  - [Docker Compose (v2.0+)](https://docs.docker.com/compose/install/)

---

## DNS Configuration

1. **Panel Domain:**
   - Create an **A record** for your panel server.
   - **Example:** `panel.yourdomain.com` → *panel_server_ip*
   - You may proxy through Cloudflare if desired.

2. **Wings Domain:**
   - Create an **A record** for your wings server.
   - **Example:** `wings.yourdomain.com` → *wings_server_ip*
   - **Important:** Do **not** proxy through Cloudflare (a direct connection is required for SFTP).

---

## Installation

### Quick Start (Recommended)

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/EdyTheCow/pterodactyl-docker.git
   cd pterodactyl-docker
   ```

2. **Run the Setup Script:**
   ```bash
   ./setup-keys.sh
   ```
   *This script will guide you through the initial setup process.*

---

### Manual Installation

#### 1. Set Up Traefik (Required on Both Servers)

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/EdyTheCow/pterodactyl-docker.git
   cd pterodactyl-docker
   ```

2. **Set SSL Certificate Permissions:**
   ```bash
   sudo chmod 600 _base/data/traefik/acme.json
   ```

3. **Launch Traefik:**
   ```bash
   cd _base/compose
   docker-compose up -d
   ```

---

#### 2. Set Up the Panel (Panel Server Only)

1. **Prepare the Environment File:**
   ```bash
   cd panel/compose
   cp .env.template .env
   ```

2. **Generate Secure Credentials:**

   Generate database passwords and application keys by running:
   ```bash
   # Generate database passwords
   DB_PASSWORD=$(openssl rand -base64 32)
   DB_ROOT_PASSWORD=$(openssl rand -base64 32)
   echo "DB_PASSWORD=$DB_PASSWORD"
   echo "DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD"

   # Generate application keys
   HASHIDS_SALT=$(openssl rand -base64 20)
   APP_KEY="base64:$(openssl rand -base64 32)"
   echo "HASHIDS_SALT=$HASHIDS_SALT"
   echo "APP_KEY=$APP_KEY"
   ```
   **Important:** Save these values securely.

3. **Edit the `.env` File:**
   ```bash
   nano .env
   ```
   Update the following:
   - **PANEL_DOMAIN:** Set to your panel domain (e.g., `panel.yourdomain.com`).
   - **APP_URL:** Set to `https://your-panel-domain`.
   - Paste the generated passwords and keys.
   - Configure mail settings as needed.

4. **Start the Panel Containers:**
   ```bash
   docker-compose up -d
   ```

5. **Create an Admin User:**
   ```bash
   docker-compose run --rm panel php artisan p:user:make
   ```
   Follow the on-screen prompts to set up your admin account.

6. **Access the Panel:**
   Open your browser and navigate to `https://your-panel-domain` to log in.

---

#### 3. Set Up Wings (Wings Server Only)

1. **Create a Docker Network (Run on the Wings Server):**
   ```bash
   docker network create pterodactyl
   ```

2. **Prepare the Wings Environment File:**
   ```bash
   cd wings/compose
   cp .env.template .env
   ```

3. **Edit the Wings `.env` File:**
   ```bash
   nano .env
   ```
   Update the following:
   - **WINGS_DOMAIN:** Set to your wings domain (e.g., `wings.yourdomain.com`).

4. **Configure Wings in the Panel:**
   - Log in to your Panel admin area.
   - Navigate to **Locations** and add a new Location.
   - Create a new Node with these key settings:
     - **FQDN:** `wings.yourdomain.com`
     - **Behind Proxy:** Enabled (required for Traefik)
     - **Daemon Port:** `443` (for HTTPS)
     - **Memory:** Set to your available RAM minus 1GB (reserve for the system)
     - **Disk Space:** Set to your available space minus 10GB (reserve for the system)

5. **Update the Provided Wings Configuration:**
   The repository includes a sample `config.yml` file. Open the file and paste your specific Wings configuration details (as provided by the Panel in the Node configuration):
   ```bash
   nano wings/data/wings/etc/config.yml
   ```
   *Simply replace the placeholder information with your actual configuration data.*

6. **Start Wings:**
   ```bash
   docker-compose up -d
   ```

7. **Verify the Connection:**
   - In the Panel, navigate to **Nodes** and ensure the node status shows as "Connected."
   - Optionally, create a test server to verify proper functionality.

---

## Security Recommendations

- **Store Credentials Safely:**  
  Save all generated passwords, keys, and sensitive information in a secure password manager.

- **File Permissions:**
  - Ensure `.env` files have restrictive permissions (e.g., `600`).
  - The `acme.json` file should also be kept secure (set to `600` permissions).

- **Do Not Share Sensitive Files:**  
  Never expose your `.env` files or credentials publicly.

---

## Troubleshooting

- **Panel Not Loading:**
  ```bash
  # Check Traefik logs:
  docker-compose logs traefik

  # Check Panel logs:
  docker-compose logs panel
  ```

- **Wings Not Connecting:**
  ```bash
  # Verify the Docker network exists:
  docker network ls | grep pterodactyl

  # Check Wings logs:
  docker-compose logs wings
  ```

- **Database Issues:**
  ```bash
  # Check database logs:
  docker-compose logs database
  ```

---

## Credits

- **Logo:** Created by Wob – [Dribbble.com/wob](https://dribbble.com/wob)
```