# portfolio-shell-automation

Shell script automation for a PostgreSQL-backed PHP portfolio website.

One script installs everything and deploys the site on a fresh Ubuntu VM; a
second script tears it back down so you can test again from a clean state.

## Files

| File | Purpose |
|------|---------|
| `setup_portfolio.sh` | Installs Apache, PostgreSQL, PHP; creates the DB + user; loads the schema; deploys the site; wires up Apache. |
| `purge_portfolio.sh` | Removes the database, user, web files, and env vars so you can re-run setup cleanly. |
| `init.sql` | Database schema, sample data, and table/sequence grants. Idempotent (drops tables first). |
| `index.php` | Portfolio homepage. Reads DB credentials from environment variables. |

## Usage

On a fresh Ubuntu VM:

```bash
git clone https://github.com/Danish20699/portfolio-shell-automation.git
cd portfolio-shell-automation
chmod +x setup_portfolio.sh purge_portfolio.sh
./setup_portfolio.sh
```

Then open <http://localhost> in a browser.

To reset and start over:

```bash
./purge_portfolio.sh
```

## Notes

- Credentials are read by PHP from Apache environment variables
  (`PGHOST`, `PGUSER`, `PGPASSWORD`, `PGPORT`, `PGDATABASE`), not hardcoded in
  the page.
- `init.sql` grants schema, table, and sequence privileges to `portfolio_user`
  so the app can read the data without permission errors.
- Web files are set to `755` ownership `www-data` — never `777`.
