#!/bin/bash
#
# setup_portfolio.sh
# One-shot automation: installs Apache, PostgreSQL, PHP, creates the database
# and user, loads the schema, deploys the portfolio site, and wires up Apache.
#
# Run from INSIDE the cloned repo (index.php and init.sql sit next to this file):
#   chmod +x setup_portfolio.sh
#   ./setup_portfolio.sh
#
# 'set -e' makes the script stop on the first error instead of ploughing on.
set -e

# ===== Configuration Variables =====
DB_NAME="portfolio_db"
DB_USER="portfolio_user"
DB_PASS="danish1p"
DB_PORT="5432"
DB_HOST="localhost"

# Directory this script lives in, so we can find index.php / init.sql
# regardless of where it is run from.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo " Portfolio automated setup starting"
echo "========================================="

# ===== 1. Update system & install dependencies =====
echo ">>> Updating system and installing packages..."
sudo apt update -y
sudo apt install -y apache2 postgresql postgresql-contrib php libapache2-mod-php php-pgsql

# ===== 2. Start & enable services =====
echo ">>> Starting and enabling Apache and PostgreSQL..."
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl start postgresql
sudo systemctl enable postgresql

# ===== 3. Create database and user =====
# We check first so re-runs don't error on "already exists".
echo ">>> Creating database and user (if they do not already exist)..."

sudo -u postgres psql <<SQL
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   ELSE
      ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$do\$;
SQL

# Create the database only if it is missing (CREATE DATABASE can't run in DO block).
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "${DB_NAME}"; then
   sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"

# ===== 4. Load schema, data, and table-level grants =====
echo ">>> Loading schema and data from init.sql..."
sudo -u postgres psql -d "${DB_NAME}" -f "${SCRIPT_DIR}/init.sql"

# ===== 5. Deploy web files =====
echo ">>> Deploying portfolio files to Apache web root..."
sudo rm -f /var/www/html/index.html
sudo cp "${SCRIPT_DIR}"/*.php /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# ===== 6. Configure Apache environment variables =====
# PHP reads these (PGHOST, PGUSER, etc.) so no credentials live in the code.
echo ">>> Configuring database environment variables for Apache..."
sudo tee -a /etc/apache2/envvars > /dev/null <<ENVVARS

# ---- Portfolio DB credentials (added by setup_portfolio.sh) ----
export PGHOST="${DB_HOST}"
export PGPORT="${DB_PORT}"
export PGUSER="${DB_USER}"
export PGPASSWORD="${DB_PASS}"
export PGDATABASE="${DB_NAME}"
ENVVARS

# ===== 7. Restart Apache to apply everything =====
echo ">>> Restarting Apache..."
sudo systemctl restart apache2

echo "========================================="
echo " Portfolio website setup complete!"
echo " Visit http://localhost to view your site."
echo "========================================="
