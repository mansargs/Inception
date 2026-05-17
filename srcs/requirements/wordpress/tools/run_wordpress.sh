#!/bin/bash
set -e

# Read passwords from Docker secrets files
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
WORDPRESS_ROOT_PASSWORD=$(cat /run/secrets/wp_root_password)

sed -i "s/listen = .*/listen = 0.0.0.0:9000/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

cd /var/www/html

if [ ! -f "wp-login.php" ]; then
	echo "[WordPress] Downloading WordPress core..."
	wp core download --allow-root
	echo "[WordPress] Core downloaded successfully."
else
	echo "[WordPress] Core already present — skipping."
fi

echo "[WordPress] Waiting for MariaDB..."
until bash -c "echo > /dev/tcp/$MYSQL_HOSTNAME/3306" 2>/dev/null; do
	echo "[WordPress] Not ready — retrying in 2s..."
	sleep 2
done
echo "[WordPress] Database is ready."

echo "[WordPress] Writing wp-config.php..."
wp config create \
	--dbname="$MYSQL_DATABASE" \
	--dbuser="$MYSQL_USER" \
	--dbpass="$MYSQL_PASSWORD" \
	--dbhost="$MYSQL_HOSTNAME" \
	--dbcharset="utf8mb4" \
	--force \
	--allow-root

if ! wp core is-installed --allow-root 2>/dev/null; then
	echo "[WordPress] Installing WordPress..."
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ROOT_USERNAME" \
		--admin_password="$WORDPRESS_ROOT_PASSWORD" \
		--admin_email="$WORDPRESS_ROOT_EMAIL" \
		--skip-email \
		--allow-root

	echo "[WordPress] Creating subscriber user..."
	wp user create "$WORDPRESS_USER_USERNAME" "$WORDPRESS_USER_EMAIL" \
		--role=subscriber \
		--user_pass="$WORDPRESS_USER_PASSWORD" \
		--allow-root

	echo "[WordPress] Installing theme..."
	wp theme install twentytwentytwo --activate --allow-root
else
	echo "[WordPress] Already installed — skipping."
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "[WordPress] Ready. Starting PHP-FPM..."
exec "$@"
