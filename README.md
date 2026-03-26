*This project has been created as part of the 42 curriculum by mabuyahy.*

# Inception

## Description

**Inception** is a system administration project from the 42 curriculum that focuses on setting up a small infrastructure of Docker containers using **docker-compose**. The goal is to deepen understanding of containerization, service orchestration, and system administration best practices.

The project deploys a fully functional **WordPress website** served over **HTTPS**, backed by a **MariaDB** database, and fronted by an **NGINX** reverse proxy — each running in its own isolated Docker container built from custom Dockerfiles based on Alpine Linux / Debian.

### Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                   Docker Network                     │
│                (inception_network)                    │
│                                                      │
│  ┌──────────┐    ┌─────────────┐    ┌────────────┐  │
│  │  NGINX   │───▶│  WordPress  │───▶│  MariaDB   │  │
│  │ :443 SSL │    │  PHP-FPM    │    │  :3306     │  │
│  │(Alpine)  │    │  :9000      │    │ (Debian)   │  │
│  └──────────┘    │  (Alpine)   │    └────────────┘  │
│       ▲          └─────────────┘          │         │
│       │                │                  │         │
└───────┼────────────────┼──────────────────┼─────────┘
        │                │                  │
     Port 443      wordpress_data      mariadb_data
    (host bind)     (bind mount)       (bind mount)
```

### Services

| Service       | Base Image       | Role                                    |
|---------------|------------------|-----------------------------------------|
| **NGINX**     | `alpine:3.18`    | Reverse proxy, SSL/TLS termination      |
| **WordPress** | `alpine:3.18`    | PHP-FPM application server with WP-CLI  |
| **MariaDB**   | `debian:bullseye`| Relational database for WordPress       |

### Design Choices

- **Custom Dockerfiles**: Every service is built from scratch using official base images (no pre-built WordPress/NGINX/MariaDB images), ensuring full control over each layer.
- **Alpine Linux**: Used for NGINX and WordPress to minimize image size and attack surface.
- **Self-signed SSL**: NGINX generates a self-signed certificate supporting TLSv1.2 and TLSv1.3.
- **WP-CLI**: WordPress is installed and configured programmatically via WP-CLI for reproducibility.
- **Entrypoint scripts**: MariaDB and WordPress use initialization scripts that handle first-run setup and are idempotent on restarts.
- **Bind-mount volumes**: Persistent data is stored on the host filesystem under `/home/<user>/data/` for easy inspection and backup.
- **Automatic restart**: All containers are configured with `restart: always`.

---

## Project Description — Docker & Comparisons

### Why Docker?

Docker is used in this project to isolate each service (NGINX, WordPress, MariaDB) into its own container, ensuring a reproducible and portable deployment. Docker Compose orchestrates the multi-container setup, managing dependencies, networking, and volumes declaratively through a single YAML file.

### Virtual Machines vs Docker

| Aspect              | Virtual Machines                         | Docker Containers                        |
|---------------------|------------------------------------------|------------------------------------------|
| **Isolation**       | Full OS-level isolation via hypervisor   | Process-level isolation via namespaces/cgroups |
| **Resource usage**  | Heavy — each VM runs a full guest OS     | Lightweight — shares the host kernel     |
| **Startup time**    | Minutes                                  | Seconds                                  |
| **Image size**      | Gigabytes                                | Megabytes                                |
| **Portability**     | Tied to hypervisor format                | Runs on any Docker-compatible host       |
| **Use case**        | Strong isolation, different OS kernels   | Microservices, CI/CD, rapid deployment   |

> **This project uses Docker** because we need lightweight, fast, and reproducible service containers — not full OS isolation.

### Secrets vs Environment Variables

| Aspect              | Environment Variables                    | Docker Secrets                            |
|---------------------|------------------------------------------|-------------------------------------------|
| **Storage**         | Stored in `.env` file or shell           | Encrypted at rest in Docker Swarm         |
| **Visibility**      | Visible via `docker inspect`, `/proc`    | Mounted as files in `/run/secrets/`, not in inspect |
| **Scope**           | Available to all processes in container  | Only available to the target service      |
| **Requires Swarm?** | No                                       | Yes (Swarm mode only)                     |
| **Security**        | Less secure — easily leaked in logs/inspect | More secure — encrypted, scoped access  |

> **This project uses environment variables** (via `.env` file) because Docker Secrets require Swarm mode, which is outside the project scope. Sensitive values (passwords, credentials) are kept in a `.env` file that is **not committed** to version control.

### Docker Network vs Host Network

| Aspect              | Docker Bridge Network                    | Host Network                              |
|---------------------|------------------------------------------|-------------------------------------------|
| **Isolation**       | Containers are on an isolated virtual network | Container shares the host's network stack |
| **Port mapping**    | Explicit port publishing required (`-p`) | No mapping needed, uses host ports directly |
| **Inter-container** | Containers communicate via service names (DNS) | Containers communicate via `localhost`  |
| **Security**        | Better — containers are isolated from host | Lower — container has full host network access |
| **Performance**     | Slight overhead from NAT/bridge          | No overhead, native performance           |

> **This project uses a bridge network** (`inception_network`) to isolate inter-container traffic. Services communicate by name (e.g., `wordpress:9000`, `mariadb:3306`), and only port 443 is exposed to the host.

### Docker Volumes vs Bind Mounts

| Aspect              | Docker Volumes                           | Bind Mounts                               |
|---------------------|------------------------------------------|-------------------------------------------|
| **Management**      | Managed by Docker (`docker volume` CLI)  | Managed by the user (host filesystem path) |
| **Location**        | Stored in Docker's storage area          | Any path on the host filesystem           |
| **Portability**     | More portable across environments        | Tied to host directory structure           |
| **Performance**     | Optimized by Docker on Linux             | Direct filesystem access, depends on host  |
| **Backup**          | Requires `docker` commands               | Standard filesystem tools (cp, rsync, etc.) |
| **Inspection**      | Via `docker volume inspect`              | Direct access on host                      |

> **This project uses bind mounts** (configured as Docker named volumes with `driver_opts: type: none, o: bind`) to store MariaDB and WordPress data under `/home/<user>/data/`. This allows easy inspection and backup while still benefiting from Docker's named volume interface.

---

## Instructions

### Prerequisites

- **Docker** and **Docker Compose** installed on your system.
- **Make** installed.
- A `.env` file at `srcs/.env` containing the required environment variables:

```env
# Domain
DOMAIN_NAME=mabuyahy.42.fr

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=<your_password>
MYSQL_ROOT_PASSWORD=<your_root_password>

# WordPress
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=<your_password>
WORDPRESS_DB_HOST=mariadb
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=<your_admin_password>
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=editor
WORDPRESS_USER_EMAIL=editor@example.com
WORDPRESS_USER_PASSWORD=<your_user_password>
```

- Add the domain to your `/etc/hosts` file:

```bash
echo "127.0.0.1 mabuyahy.42.fr" | sudo tee -a /etc/hosts
```

### Build & Run

```bash
make            # Build images and start all containers
```

Then open **https://mabuyahy.42.fr** in your browser (accept the self-signed certificate warning).

### Available Make Targets

| Command        | Description                                         |
|----------------|-----------------------------------------------------|
| `make`         | Build and start all containers in detached mode     |
| `make down`    | Stop and remove containers                          |
| `make clean`   | Stop containers and remove volumes                  |
| `make fclean`  | Full cleanup: containers, volumes, images, and data |
| `make re`      | Full cleanup then rebuild everything                |
| `make status`  | Show running container status                       |
| `make start`   | Start stopped containers                            |
| `make stop`    | Stop running containers                             |
| `make restart` | Restart all containers                              |

---

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/packages)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [42 Inception Subject](https://projects.intra.42.fr/projects/inception)

### AI Usage

AI tools (GitHub Copilot / ChatGPT) were used during this project for:
- **Documentation**: Generating and structuring this README file.
- **Debugging**: Troubleshooting Docker build errors and container networking issues.
- **Configuration reference**: Clarifying NGINX, PHP-FPM, and MariaDB configuration directives.

All code was reviewed, tested, and understood before being integrated into the project. No AI-generated code was used blindly.
