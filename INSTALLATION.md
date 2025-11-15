# Installation Guide - Mountable Engine

This guide shows how to mount the Data Migration Tool in your Rails application.

---

## Step 1: Add to Gemfile

In your Rails app's `Gemfile`:

```ruby
# For local development
gem 'data_migration', path: '../data_migration_for_rails'

# OR for production (after publishing to git)
# gem 'data_migration', git: 'https://github.com/yourusername/data_migration'
```

Then run:
```bash
bundle install
```

---

## Step 2: Copy Migrations

The engine's migrations need to be copied to your app:

```bash
bundle exec rake data_migration:install:migrations
```

This creates migrations in `db/migrate/` with a timestamp prefix.

---

## Step 3: Run Migrations

```bash
bundle exec rails db:migrate
```

This creates the following tables in your database:
- `users` - Migration tool users (separate from your app's users)
- `migration_plans`
- `migration_steps`
- `migration_executions`
- `migration_records`

---

## Step 4: Mount Routes

In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # Your existing routes
  # ...

  # Mount the data migration engine
  mount DataMigration::Engine => "/data_migration"
end
```

---

## Step 5: Create Admin User

Run the seed task:

```bash
bundle exec rails db:seed
```

This will prompt you for admin credentials.

---

## Step 6: Access the Tool

Start your Rails server:

```bash
bundle exec rails server
```

Navigate to: **http://localhost:3000/data_migration**

Login with the admin credentials you created.

---

## How It Works

### Database Access
The engine runs **inside your Rails app** and has direct access to:
- ✅ All your app's models (Company, Employee, etc.)
- ✅ Your app's database connection
- ✅ All associations and validations

### Separate Tables
The migration tool uses its own tables (users, migration_plans, etc.) which are separate from your app's data.

### Services
When you export/import:
```ruby
# In export service
model_class = "Company".constantize  # ← Accesses YOUR Company model
records = model_class.all  # ← Uses YOUR database
```

---

## Configuration

### Email (Optional)
For email confirmations, configure in `config/environments/development.rb`:

```ruby
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

### Sidekiq (Required for Background Jobs)
Ensure Redis and Sidekiq are running:

```bash
# Terminal 1
redis-server

# Terminal 2
bundle exec sidekiq
```

---

## Uninstallation

To remove the engine:

1. Remove from `Gemfile`
2. Run `bundle install`
3. Rollback migrations:
```bash
bundle exec rails db:rollback STEP=5  # Adjust number based on migrations
```

---

## Troubleshooting

### "Model not found" error
Make sure your model names in migration steps exactly match your app's models.

### Routes conflict
If `/data_migration` conflicts with your routes, mount at a different path:
```ruby
mount DataMigration::Engine => "/admin/migrations"
```

### Database connection
The engine uses your app's database connection automatically.

---

## Next Steps

See [README.md](README.md) for usage guide and [QUICKSTART.md](QUICKSTART.md) for a quick tutorial.