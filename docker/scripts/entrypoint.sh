#!/bin/sh

set -eu

cd /var/www/glpi

echo "[GLPI] Starting container initialization..."

# Validate required environment variables
: "${DB_HOST:?DB_HOST is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"

DB_PORT="${DB_PORT:-3306}"
GLPI_AUTO_INSTALL="${GLPI_AUTO_INSTALL:-false}"

# Wait for database connectivity
echo "[GLPI] Waiting for database connection..."

attempt=0
max_attempts=30

until php -r '
mysqli_report(MYSQLI_REPORT_OFF);
$db = @new mysqli(
    getenv("DB_HOST"),
    getenv("DB_USER"),
    getenv("DB_PASSWORD"),
    getenv("DB_NAME"),
    (int)(getenv("DB_PORT") ?: 3306)
);
exit($db->connect_errno ? 1 : 0);
'; do
    attempt=$((attempt + 1))

    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "[GLPI] ERROR: Database connection failed."
        exit 1
    fi

    echo "[GLPI] Database unavailable. Retry $attempt/$max_attempts"
    sleep 5
done

echo "[GLPI] Database connection successful!"

# Check whether the database contains tables
TABLE_COUNT=$(php -r '
$db = new mysqli(
    getenv("DB_HOST"),
    getenv("DB_USER"),
    getenv("DB_PASSWORD"),
    getenv("DB_NAME"),
    (int)(getenv("DB_PORT") ?: 3306)
);

$result = $db->query("SHOW TABLES");
echo $result->num_rows;
$db->close();
')

CONFIG_FILE="config/config_db.php"
KEY_FILE="config/glpicrypt.key"

echo "[GLPI] Database contains $TABLE_COUNT tables."

# Detect installation state
if [ -s "$CONFIG_FILE" ] && [ -s "$KEY_FILE" ] && [ "$TABLE_COUNT" -gt 0 ]; then

    echo "[GLPI] Existing installation detected."
    echo "[GLPI] Preserving existing database and configuration."

elif [ ! -e "$CONFIG_FILE" ] && [ ! -e "$KEY_FILE" ] && [ "$TABLE_COUNT" -eq 0 ]; then

    if [ "$GLPI_AUTO_INSTALL" != "true" ]; then
        echo "[GLPI] ERROR: Automatic installation is disabled."
        exit 1
    fi

    echo "[GLPI] Empty database detected."
    echo "[GLPI] Installing GLPI..."

    php bin/console database:install \
        --db-host="$DB_HOST" \
        --db-port="$DB_PORT" \
        --db-name="$DB_NAME" \
        --db-user="$DB_USER" \
        --db-password="$DB_PASSWORD" \
        --no-telemetry \
        --no-interaction

    echo "[GLPI] Installation completed."

else

    echo "[GLPI] ERROR: Inconsistent installation state."
    echo "[GLPI] Check your database, configuration and encryption keys."
    echo "[GLPI] Refusing to overwrite existing data."
    exit 1

fi

# Restrict sensitive configuration file permissions
echo "[GLPI] Securing configuration files..."

chmod 640 "$CONFIG_FILE" "$KEY_FILE"

if [ -f config/oauth.pem ]; then
    chmod 640 config/oauth.pem
fi

# Start the web server
echo "[GLPI] Initialization complete."
echo "[GLPI] Starting Apache..."

exec apache2-foreground