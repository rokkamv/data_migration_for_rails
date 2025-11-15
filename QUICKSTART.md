# Quick Start Guide

Get your Data Migration Tool up and running in 5 minutes!

## 1. Prerequisites Check

```bash
# Check Ruby version (should be 3.0.0)
ruby -v

# Check PostgreSQL is running
psql --version

# Check Redis is installed
redis-cli --version
```

## 2. Installation (3 commands)

```bash
# Install dependencies
bundle install

# Setup database
bundle exec rails db:create db:migrate

# Create admin user (will prompt for email/password)
bundle exec rails db:seed
```

## 3. Start Services (3 terminals)

**Terminal 1 - Redis:**
```bash
redis-server
```

**Terminal 2 - Sidekiq:**
```bash
bundle exec sidekiq
```

**Terminal 3 - Rails:**
```bash
bundle exec rails server
```

## 4. Access Application

Open browser: **http://localhost:3000**

Login with the admin credentials you created.

---

## First Migration in 2 Minutes

### Create a Plan
1. Click **"New Migration Plan"**
2. Name: "Test Migration"
3. Click **"Create Migration Plan"**

### Add a Step
1. Click **"Add Step"**
2. Model Name: `User` (or any model in your app)
3. Execution Order: `1`
4. Click **"Create Step"**

### Export
1. Click **"Export"** button
2. Wait for completion (check execution page)
3. Click **"Download Export Archive"**

### Import
1. Click **"Import"** button
2. Upload the `.tar.gz` file you just downloaded
3. Click **"Start Import"**
4. Monitor progress!

---

## Development Users

Three users are created automatically in development mode:

| Email | Password | Role | Permissions |
|-------|----------|------|-------------|
| *(your admin email)* | *(your password)* | Admin | Full access |
| operator@example.com | Operator123! | Operator | Execute exports/imports |
| viewer@example.com | Viewer123! | Viewer | Read-only |

Test role permissions by logging in as different users!

---

## Common Issues

**"Can't connect to database"**
```bash
# Check PostgreSQL is running
sudo service postgresql status

# Update config/database.yml with correct credentials
```

**"Redis connection refused"**
```bash
# Start Redis
redis-server
```

**"Sidekiq not processing jobs"**
```bash
# Make sure Sidekiq is running in a separate terminal
bundle exec sidekiq
```

---

## Next Steps

- Read the full [README.md](README.md) for advanced features
- Configure your migration steps with filters and associations
- Set up email for production deployments
- Explore the execution history and audit trails

---

**Need Help?** Check the Troubleshooting section in README.md
