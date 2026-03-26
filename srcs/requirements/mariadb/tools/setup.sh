#!/bin/bash

# Initialize the MySQL data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB temporarily with skip-grant-tables
mysqld_safe --skip-grant-tables &

# Wait for MariaDB to be ready
while ! mysqladmin ping --silent; do
    echo "Waiting for MariaDB to start..."
    sleep 1
done

# Check if our database already exists (in case of restart with existing volume)
DB_EXISTS=$(mysql -u root -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" | grep "${MYSQL_DATABASE}")

if [ -z "$DB_EXISTS" ]; then
    echo "Creating database and user..."

    mysql -u root << EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "Database setup complete!"
else
    echo "Database already exists, skipping setup."
fi

# Stop the temporary MariaDB
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

# Wait for it to fully stop
while mysqladmin ping --silent 2>/dev/null; do
    echo "Waiting for MariaDB to stop..."
    sleep 1
done

# Start MariaDB in the foreground (normal mode, passwords required)
exec mysqld_safe