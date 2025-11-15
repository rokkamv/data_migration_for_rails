# Data Migration Tool for Rails

A web-based application for migrating data between Rails application environments. Export data from one environment, transfer the archive, and import it into another environment with full audit trails and role-based access control.

## Features

✅ **Role-Based Access Control**
- Admin: Full access to plans, steps, users, and executions
- Operator: Can execute exports/imports
- Viewer: Read-only access

✅ **Migration Plans**
- Configure reusable migration plans
- Define migration steps with execution order
- Filter records with ActiveRecord queries
- Map associations and foreign keys

✅ **Export & Import**
- Export to compressed tar.gz archives
- Import with conflict resolution (create/update/skip)
- Timestamp-based update logic
- Background job processing with Sidekiq

✅ **Monitoring & Audit**
- Real-time progress tracking (auto-refresh)
- Execution history with detailed stats
- Record-level audit trail
- Error logging and reporting

✅ **Security**
- Email verification with Devise confirmable
- Pundit authorization policies
- Strong parameters validation
- Prevent user deletion with execution history

---

## Prerequisites

- Ruby 3.0.0
- PostgreSQL
- Redis (for Sidekiq background jobs)
- Rails 7.1.5

---

## Installation

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd data_migration_for_rails
bundle install
```

### 2. Configure Database

Update `config/database.yml` with your PostgreSQL credentials or use environment variables:

```bash
export LOCAL_DB_USERNAME=your_username
export LOCAL_DB_PASSWORD=your_password
```

### 3. Create and Migrate Database

```bash
bundle exec rails db:create
bundle exec rails db:migrate
```

### 4. Seed Initial Admin User

The seed script will prompt for admin credentials:

```bash
bundle exec rails db:seed
```

Or provide via environment variables:

```bash
ADMIN_EMAIL=admin@yourdomain.com ADMIN_PASSWORD=SecurePass123! bundle exec rails db:seed
```

**Development users** (created automatically in development mode):
- `operator@example.com` / `Operator123!`
- `viewer@example.com` / `Viewer123!`

---

## Running the Application

### Start Redis (required for Sidekiq)

```bash
redis-server
```

### Start Sidekiq (background jobs)

```bash
bundle exec sidekiq
```

### Start Rails Server

```bash
bundle exec rails server
```

### Access the Application

Open your browser and navigate to:
```
http://localhost:3000
```

Login with the admin credentials you created during seeding.

---

## Usage Guide

### 1. Create a Migration Plan

1. Navigate to **Migration Plans** → **New Migration Plan**
2. Enter a name and description
3. Click **Create Migration Plan**

### 2. Add Migration Steps

1. Open your migration plan
2. Click **Add Step**
3. Configure:
   - **Model Name**: ActiveRecord model (e.g., `User`, `Post`)
   - **Execution Order**: Steps run in ascending order
   - **Filter Query** (optional): e.g., `where(active: true)`
   - **Column Overrides**: JSON mapping associations to export
   - **Association Overrides**: JSON for remapping foreign keys on import

Example column overrides:
```json
{
  "company": ["name", "code"],
  "role": ["title"]
}
```

### 3. Export Data

1. Go to your migration plan
2. Click **Export**
3. Wait for the background job to complete
4. Download the `.tar.gz` archive

### 4. Transfer Archive

Manually copy the `.tar.gz` file to the target environment server.

### 5. Import Data

1. On target environment, go to the same migration plan
2. Click **Import** → **Choose File**
3. Upload the `.tar.gz` archive
4. Click **Start Import**
5. Monitor progress on the execution dashboard

### 6. Review Results

- View execution details for statistics
- Check migration records for individual record actions
- Download export archives anytime from execution history

---

## Architecture

### Models

- **User**: Authentication with Devise, roles (admin/operator/viewer)
- **MigrationPlan**: Container for migration steps
- **MigrationStep**: Defines what/how to migrate for each model
- **MigrationExecution**: Tracks each export/import run
- **MigrationRecord**: Audit trail for each migrated record

### Services

- **Exports::GeneratorService**: Creates CSV tar.gz from database
- **Imports::ProcessorService**: Processes uploaded tar.gz into database

### Jobs

- **ExportJob**: Background export processing with Sidekiq
- **ImportJob**: Background import processing with Sidekiq

### Controllers

- **MigrationPlansController**: CRUD for migration plans
- **MigrationStepsController**: CRUD for migration steps
- **ExportsController**: Trigger exports
- **ImportsController**: File upload and trigger imports
- **MigrationExecutionsController**: View history and download archives
- **UsersController**: User management (admin only)

---

## Configuration

### Email Settings (for Devise confirmable)

Development uses SMTP on `localhost:1025`. For testing, use MailCatcher:

```bash
gem install mailcatcher
mailcatcher
```

View emails at: http://localhost:1080

For production, update `config/environments/production.rb` with your SMTP settings.

### File Storage

Export/import archives are stored in:
- `tmp/exports/` - Export archives
- `tmp/imports/` - Uploaded import files

Ensure these directories have write permissions.

### Background Jobs

Sidekiq configuration in `config/sidekiq.yml`. Default queue is `:default`.

---

## Security Considerations

⚠️ **Important Security Notes**:

1. **Email Confirmation**: Users must verify email before login (bypassed for seeded users)
2. **Strong Passwords**: Enforce minimum 6 characters (configure in Devise initializer)
3. **Authorization**: All actions protected by Pundit policies
4. **Audit Trail**: Cannot delete users or plans with execution history
5. **File Upload**: Only `.tar.gz` files accepted, validated on upload
6. **SQL Injection**: Filter queries use ActiveRecord (avoid raw SQL)

---

## Deployment

### Production Checklist

- [ ] Set strong `SECRET_KEY_BASE` in environment
- [ ] Configure production database credentials
- [ ] Set up production email SMTP settings
- [ ] Configure Redis for Sidekiq
- [ ] Set file storage permissions for `tmp/exports` and `tmp/imports`
- [ ] Run migrations: `RAILS_ENV=production bundle exec rails db:migrate`
- [ ] Seed admin user: `RAILS_ENV=production bundle exec rails db:seed`
- [ ] Precompile assets: `RAILS_ENV=production bundle exec rails assets:precompile`
- [ ] Start Sidekiq: `bundle exec sidekiq -e production`
- [ ] Start Rails: `RAILS_ENV=production bundle exec rails server`

### Docker Deployment

A Dockerfile is included. Build and run:

```bash
docker build -t data-migration-tool .
docker run -p 3000:3000 data-migration-tool
```

---

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/user_spec.rb
```

---

## Troubleshooting

### Sidekiq not processing jobs

- Ensure Redis is running: `redis-cli ping` (should return PONG)
- Check Sidekiq is running: `bundle exec sidekiq`
- View Sidekiq web UI: Mount at `/sidekiq` in routes

### Email confirmation not working

- Check SMTP settings in `config/environments/development.rb`
- Use MailCatcher for local testing
- For development, skip confirmation: `user.skip_confirmation!`

### Export/Import file not found

- Check `tmp/exports` and `tmp/imports` directories exist
- Verify file permissions (read/write for Rails process)

---

## Contributing

This is a personal project. For questions or issues, please contact the repository owner.

---

## License

[Specify your license here]

---

## Future Enhancements

- [ ] Real-time ActionCable progress updates (currently uses meta refresh)
- [ ] Rollback capability for imports
- [ ] Dry-run mode (preview without executing)
- [ ] Scheduled migrations with cron
- [ ] API endpoints for programmatic access
- [ ] Multi-database support
- [ ] Custom validators for migration steps
