# Inception — User Documentation

This document explains how to use and manage the Inception infrastructure as an end user or administrator.

---

## Services Overview

The Inception stack provides a **WordPress website** accessible over HTTPS. It is composed of three services working together:

| Service       | What it does                                                                 |
|---------------|------------------------------------------------------------------------------|
| **NGINX**     | Web server and reverse proxy. Handles HTTPS connections on port 443.         |
| **WordPress** | The website application (blog/CMS). Runs PHP-FPM on an internal port (9000).|
| **MariaDB**   | The database that stores all WordPress content (posts, users, settings).     |

All three services run in isolated Docker containers and communicate over a private network. Only NGINX is exposed to the outside world on port **443** (HTTPS).

---

## Starting and Stopping the Project

### Start the project

```bash
make
```

This builds all container images (if not already built) and starts the entire stack in the background.

### Stop the project (keep data)

```bash
make stop
```

Containers are stopped but data is preserved. Use `make start` to resume.

### Restart the project

```bash
make restart
```

### Shut down and remove containers (keep data)

```bash
make down
```

Containers are removed but volumes (database and WordPress files) remain intact.

### Full cleanup (removes everything including data)

```bash
make fclean
```

> ⚠️ **Warning**: This deletes all containers, images, volumes, **and** the persistent data directories. You will lose all WordPress content and database entries.

---

## Accessing the Website

### WordPress Site

Open your browser and navigate to:

```
https://mabuyahy.42.fr
```

> **Note**: The site uses a self-signed SSL certificate. Your browser will show a security warning — this is expected. Click **Advanced** → **Proceed** (or equivalent) to continue.

### WordPress Administration Panel

To manage the site (create posts, manage users, install plugins, change themes):

```
https://mabuyahy.42.fr/wp-admin
```

Log in with the **admin credentials** (see section below).

---

## Credentials

All credentials are stored in the file `srcs/.env`. This file is **not committed** to version control for security reasons.

### Where to find them

```bash
cat srcs/.env
```

### What credentials exist

| Credential                  | Environment Variable          | Role                              |
|-----------------------------|-------------------------------|-----------------------------------|
| WordPress Admin Username    | `WORDPRESS_ADMIN_USER`        | Full access to wp-admin panel     |
| WordPress Admin Password    | `WORDPRESS_ADMIN_PASSWORD`    | Password for the admin account    |
| WordPress Admin Email       | `WORDPRESS_ADMIN_EMAIL`       | Email for the admin account       |
| WordPress Editor Username   | `WORDPRESS_USER`              | Editor-level access to wp-admin   |
| WordPress Editor Password   | `WORDPRESS_USER_PASSWORD`     | Password for the editor account   |
| Database Root Password      | `MYSQL_ROOT_PASSWORD`         | MariaDB root access (admin only)  |
| Database User               | `MYSQL_USER`                  | Used by WordPress to connect to DB|
| Database Password           | `MYSQL_PASSWORD`              | Password for the DB user          |

### Changing credentials

1. Edit `srcs/.env` with the new values.
2. Run `make fclean && make` to rebuild everything from scratch with the new credentials.

> ⚠️ Changing database or WordPress credentials requires a full rebuild since they are set during initial container setup.

---

## Checking that Services are Running

### Quick status check

```bash
make status
```

This shows all running containers with their state, ports, and uptime. You should see three containers: `nginx`, `wordpress`, and `mariadb`, all with status **Up**.

### Verify NGINX (HTTPS)

```bash
curl -k https://mabuyahy.42.fr
```

You should receive HTML content from the WordPress site. The `-k` flag allows the self-signed certificate.

### Verify WordPress (PHP-FPM)

```bash
docker exec wordpress php81 -v
```

Should display the PHP version, confirming PHP is installed and running inside the container.

### Verify MariaDB (Database)

```bash
docker exec mariadb mysqladmin -u root -p ping
```

Enter the root password when prompted. A response of `mysqld is alive` confirms the database is running.

### View container logs

If something isn't working, check the logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

---

## Troubleshooting

| Problem                                | Solution                                                      |
|----------------------------------------|---------------------------------------------------------------|
| Browser says "site can't be reached"   | Run `make status` to check if containers are running. Run `make` if they aren't. |
| SSL certificate warning                | This is expected with self-signed certificates. Proceed past the warning. |
| "Error establishing database connection" | Check that MariaDB is running (`make status`). Verify DB credentials in `srcs/.env` match. |
| Changes to `.env` not taking effect    | Run `make fclean && make` to rebuild with new values.         |
| Domain not resolving                   | Ensure `127.0.0.1 mabuyahy.42.fr` is in your `/etc/hosts` file. |
