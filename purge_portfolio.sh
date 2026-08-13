#!/bin/bash
#
# purge_portfolio.sh
# Tears down what setup_portfolio.sh created, so you can test again from a
# clean state. It does NOT uninstall Apache/PostgreSQL/PHP (those are big
# downloads); it only removes the database, user, web files, and env vars.
#
# Usage:
#   chmod +x purge_portfolio.sh
#   ./purge_portfolio.sh
#
set -e

DB_NAME="portfolio_db"
DB_USER="portfolio_user"

echo "========================================="
echo " Purging portfolio setup"
echo "========================================="

# ===== 1. Drop the database =====
echo ">>> Dropping database ${DB_NAME} (if it exists)..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${DB_NAME};"

# ===== 2. Drop the user =====
echo ">>> Dropping user ${DB_USER} (if it exists)..."
sudo -u postgres psql -c "DROP ROLE IF EXISTS ${DB_USER};"

# ===== 3. Remove deployed web files =====
echo ">>> Removing deployed PHP files from /var/www/html..."
sudo rm -f /var/www/html/*.php

# ===== 4. Remove the env vars we appended to Apache =====
# We delete every line from our marker onward. Safe because setup only
# appends this block at the very end of the file.
echo ">>> Removing portfolio DB credentials from Apache envvars..."
sudo sed -i '/# ---- Portfolio DB credentials (added by setup_portfolio.sh) ----/,$d' /etc/apache2/envvars

# ===== 5. Restart Apache =====
echo ">>> Restarting Apache..."
sudo systemctl restart apache2

echo "========================================="
echo " Purge complete. You can run setup_portfolio.sh again."
echo "========================================="
