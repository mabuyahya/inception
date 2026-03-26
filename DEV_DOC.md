# Inception — Developer Documentation

This document describes how to set up, build, run, and manage the Inception project from a developer perspective.

---

## Setting Up the Environment from Scratch

### Prerequisites

Ensure the following are installed on your system:

| Tool              | Purpose                              | Install (Debian/Ubuntu)                  |
|-------------------|--------------------------------------|------------------------------------------|
| **Docker**        | Container runtime                    | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| **Docker Compose** | Multi-container orchestration       | Included with Docker Desktop, or install the plugin |
| **Make**          | Build automation                     | `sudo apt install make`                  |
| **Git**           | Version control                      | `sudo apt install git`                   |

Verify installation:

```bash
docker --version
docker compose version
make --version
```

### Clone the Repository

```bash
git clone <repository-url>
cd inception
```

### Configuration Files

#### 1. Environment file — `srcs/.env`

Create the file `srcs/.env` with the following variables:

```env
# Domain
DOMAIN_NAME=mabuyahy.42.fr

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=<choose_a_password>
MYSQL_ROOT_PASSWORD=<choose_a_root_password>

# WordPress
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=<same_as_MYSQL_PASSWORD>
WORDPRESS_DB_HOST=mariadb
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=<choose_admin_password>
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=editor
WORDPRESS_USER_EMAIL=editor@example.com
WORDPRESS_USER_PASSWORD=<choose_user_password>
```

> ⚠️ **Important**: This file must **never** be committed to Git. Ensure `srcs/.env` is listed in `.gitignore`.

#### 2. Domain resolution — `/etc/hosts`

Add the project domain to your local DNS:

```bash
echo "127.0.0.1 mabuyahy.42.fr" | sudo tee -a /etc/hosts
```

---

## Project Structure

```
inception/
├── Makefile                          # Build automation
├── README.md                         # Project overview
├── USER_DOC.md                       # End-user documentation
├── DEV_DOC.md                        # Developer documentation (this file)
└── srcs/
    ├── .env                          # Environment variables (not committed)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB image (debian:bullseye)
        │   ├── conf/
        │   │   └── mariadb_config.cnf  # Custom MariaDB server config
        │   └── tools/
        │       └── setup.sh          # DB initialization entrypoint script
        ├── nginx/
        │   ├── Dockerfile            # NGINX image (alpine:3.18)
        │   └── conf/
        │       └── nginx.conf        # NGINX server block configuration
        └── wordpress/
            ├── Dockerfile            # WordPress/PHP-FPM image (alpine:3.18)
            ├── conf/
            │   └── php_fpm.config    # PHP-FPM pool configuration
            └── tools/
                └── setup.sh          # WordPress installation entrypoint script
```

---

## Building and Launching the Project

### Using the Makefile

The Makefile is the primary interface for managing the project. All commands wrap `docker compose` with the correct compose file path.

| Command          | Description                                                         |
|------------------|---------------------------------------------------------------------|
| `make`           | Create data directories, build images, and start containers (`up --build -d`) |
| `make down`      | Stop and remove containers (preserves volumes)                      |
| `make clean`     | Stop containers **and** remove volumes (`down -v`)                  |
| `make fclean`    | Full cleanup: `clean` + prune all images + delete host data dirs    |
| `make re`        | `fclean` then `all` — complete rebuild from scratch                 |
| `make status`    | Show container status (`ps`)                                        |
| `make start`     | Start existing stopped containers                                   |
| `make stop`      | Stop running containers without removing them                       |
| `make restart`   | Restart all containers                                              |

### Build flow

When you run `make`, the following happens:

1. **Host directories** are created: `/home/<user>/data/mariadb` and `/home/<user>/data/wordpress`
2. **Docker Compose** reads `srcs/docker-compose.yml`
3. Each service's **Dockerfile** is built:
   - `mariadb` → `srcs/requirements/mariadb/Dockerfile`
   - `wordpress` → `srcs/requirements/wordpress/Dockerfile`
   - `nginx` → `srcs/requirements/nginx/Dockerfile`
4. Containers start in dependency order: **MariaDB** → **WordPress** → **NGINX**
5. Entrypoint scripts run inside MariaDB and WordPress to handle first-time initialization

### Manual Docker Compose commands

If you need to run commands directly (for debugging):

```bash
# Build without starting
docker compose -f srcs/docker-compose.yml build

# Start with live logs (foreground)
docker compose -f srcs/docker-compose.yml up --build

# Rebuild a single service
docker compose -f srcs/docker-compose.yml build wordpress

# View logs for a specific service
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

---

## Managing Containers and Volumes

### Container management

```bash
# List running containers
docker ps

# Execute a shell inside a container
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb bash      # MariaDB uses Debian (bash available)

# View real-time logs
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Inspect a container's configuration
docker inspect wordpress

# Check container resource usage
docker stats
```

### Volume management

```bash
# List Docker volumes
docker volume ls

# Inspect a volume
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data

# Remove all unused volumes (careful!)
docker volume prune
```

### Network inspection

```bash
# List networks
docker network ls

# Inspect the project network
docker network inspect srcs_inception_network

# Verify container connectivity
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress
```

### Database access

```bash
# Connect to MariaDB as root
docker exec -it mariadb mysql -u root -p

# Connect as the WordPress user
docker exec -it mariadb mysql -u wpuser -p wordpress

# Useful SQL commands once connected:
#   SHOW DATABASES;
#   USE wordpress;
#   SHOW TABLES;
#   SELECT user, host FROM mysql.user;
```

---

## Data Storage and Persistence

### Where data is stored

Data persists across container restarts and rebuilds (unless explicitly deleted) in two locations on the host filesystem:

| Data             | Host path                        | Container mount point         | Purpose                          |
|------------------|----------------------------------|-------------------------------|----------------------------------|
| MariaDB database | `/home/<user>/data/mariadb`      | `/var/lib/mysql`              | All database files               |
| WordPress files  | `/home/<user>/data/wordpress`    | `/var/www/html/wordpress`     | WP core, themes, plugins, uploads|

> `<user>` is resolved from the `$USER` environment variable at build time via the Makefile.

### How persistence works

The `docker-compose.yml` defines named volumes with bind mount drivers:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mabuyahy/data/mariadb
```

This means:
- Docker manages the volume by name (`mariadb_data`, `wordpress_data`)
- The actual data lives on the **host filesystem** at the specified `device` path
- Data survives `make down` (container removal)
- Data survives `make clean` (volume removal from Docker's perspective — but the host directory remains)
- Data is **deleted** only by `make fclean` (which runs `sudo rm -rf` on the data directory)

### Initialization behavior

Both MariaDB and WordPress entrypoint scripts are **idempotent**:

- **MariaDB** (`srcs/requirements/mariadb/tools/setup.sh`): Checks if `/var/lib/mysql/mysql` exists. If not, runs `mysql_install_db` and creates the database/user. On subsequent starts, skips initialization.
- **WordPress** (`srcs/requirements/wordpress/tools/setup.sh`): Checks if `wp-config.php` exists. If not, downloads WordPress core via WP-CLI and runs the installation. On subsequent starts, skips setup and directly starts PHP-FPM.

### Backing up data

```bash
# Backup MariaDB
docker exec mariadb mysqldump -u root -p wordpress > backup.sql

# Backup WordPress files
sudo cp -r /home/$(whoami)/data/wordpress ./wordpress_backup

# Restore MariaDB from backup
docker exec -i mariadb mysql -u root -p wordpress < backup.sql
```

---

## Adding or Modifying a Service

To add a new service or modify an existing one:

1. **Create/edit the Dockerfile** in `srcs/requirements/<service>/Dockerfile`
2. **Add configuration files** in `srcs/requirements/<service>/conf/`
3. **Add entrypoint scripts** in `srcs/requirements/<service>/tools/`
4. **Register the service** in `srcs/docker-compose.yml` with appropriate `build`, `volumes`, `networks`, and `depends_on`
5. **Rebuild**: `make re`

### Key conventions

- Base images must be either **Alpine** or **Debian** (no pre-built application images)
- Each container runs **one process** in the foreground (PID 1)
- Entrypoint scripts must be **idempotent** — safe to run on fresh start or restart with existing data
- Environment variables come from `srcs/.env` — never hardcode secrets in Dockerfiles or scripts
- All services connect to the `inception_network` bridge network
- Only NGINX exposes ports to the host
