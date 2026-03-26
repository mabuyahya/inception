#!/bin/sh

echo "Waiting for MariaDB to be ready..."
while ! mysqladmin ping -h mariadb --silent; do
    echo "MariaDB is not ready yet... waiting"
    sleep 2
done

cd /var/www/html/wordpress

if [ ! -f "wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root

    echo "Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="My Inception Site" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --allow-root

    echo "WordPress setup complete!"
else
    echo "WordPress already configured, skipping setup."
    
    # Ensure the second user exists even if WordPress was already configured
    if ! wp user get "${WORDPRESS_USER}" --allow-root > /dev/null 2>&1; then
        echo "Creating additional user..."
        wp user create \
            "${WORDPRESS_USER}" \
            "${WORDPRESS_USER_EMAIL}" \
            --role=editor \
            --user_pass="${WORDPRESS_USER_PASSWORD}" \
            --allow-root
    fi
fi

# Start PHP-FPM in the foreground (keeps the container alive)
echo "Starting PHP-FPM..."
exec /usr/sbin/php-fpm81 --nodaemonize