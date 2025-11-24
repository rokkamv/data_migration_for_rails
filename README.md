# Data Migration - Rails Engine

A mountable Rails engine for migrating data between Rails application environments with full audit trails, role-based access control, and dependency management.

## Features

- **Role-Based Access Control** - Admin, Operator, and Viewer roles
- **Migration Plans** - Reusable migration configurations with execution order
- **Dynamic Filtering** - ActiveRecord queries with runtime parameter substitution
- **Dependency Management** - Maintain referential integrity across related models
- **Association Handling** - Remap foreign keys and handle polymorphic associations
- **Attachment Handling** - Export/import Active Storage attachments with URL or raw data modes
- **Background Processing** - Sidekiq-based async exports and imports
- **Audit Trail** - Complete execution history and record-level tracking
- **Real-time Progress** - ActionCable integration for live updates

---

## Installation

### 1. Add to Gemfile

```ruby
gem 'data_migration', path: 'path/to/data_migration_for_rails'
```

```bash
bundle install
bin/rails data_migration:install:migrations
bin/rails db:migrate
```

### 2. Mount Routes

In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount DataMigration::Engine, at: "/data_migration"
end
```

### 3. Seed Initial Admin User

```bash
bin/rails db:seed
```

This creates an admin user with independent authentication:
- **Email:** admin@datamigration.local
- **Password:** password

**Change the password immediately** after first login! Admin users can create additional users via the "Users" menu.

### 4. Configure Sidekiq

In `config/application.rb`:

```ruby
config.active_job.queue_adapter = :sidekiq
```

Start services:
```bash
redis-server
bundle exec sidekiq
```

---

## Prerequisites

- Ruby 3.0+
- Rails 7.0+
- Redis
- Devise (for authentication)
- Pundit (for authorization)
- Active Storage (optional, for attachment handling)

---

## Usage

### 1. Create Migration Plan

Navigate to `/data_migration/migration_plans` and create a new plan.

### 2. Add Migration Steps

Configure each step with:

- **Model Name**: Select from dropdown (shows fields and attachments)
- **Sequence**: Execution order
- **Filter Query** (optional): ActiveRecord query with optional placeholders

Examples:
```ruby
where(active: true).limit(100)
where("created_at > ?", "{{cutoff_date}}")
```

- **Column Overrides**: Export association attributes
- **Association ID Mappings**: Remap foreign keys on import
- **Dependee Attribute Mapping**: Filter based on parent step's exported records
- **Attachment Export Mode**: Choose how to handle Active Storage attachments:
  - **Ignore** - Skip attachments
  - **URL** - Export attachment URLs (for cloud storage)
  - **Raw Data** - Export actual files in archive (for local storage)

### 3. Export

Click **Export**, fill in any filter parameters, and download the `.tar.gz` archive.

### 4. Import

On target environment, click **Import**, upload the archive, and select conflict resolution strategy.

---

## Advanced Features

### Dynamic Filter Parameters

Use `{{placeholder}}` syntax in filter queries. Values are collected at export time and validated before execution.

### Referential Integrity

Set **Depends On Step** and **Dependee Attribute Mapping** to ensure child records only include those referencing exported parent records.

Example: Export only employees whose companies were exported.

### Polymorphic Associations

Configure polymorphic associations with type-specific lookup attributes for proper ID remapping on import.

---

## Security

- Pundit-based authorization on all actions
- Strong parameter validation
- Safe ActiveRecord query evaluation
- Multi-layer input validation
- Complete audit trail

---

## Troubleshooting

**Sidekiq not processing:**
- Check Redis: `redis-cli ping`
- Verify `config.active_job.queue_adapter = :sidekiq`
- Check logs: `tail -f log/sidekiq.log`

**Filter parameter errors:**
- Ensure placeholders are inside quotes: `"{{param}}"` not `{{param}}`
- Provide all required parameter values before export

**Model not found:**
- Verify exact ActiveRecord class name
- Check lookup attributes exist on target models

---

## License

**Proprietary Software** - All rights reserved.

This software is confidential and proprietary. Unauthorized copying, distribution, or use is strictly prohibited.

Copyright © 2025. All rights reserved.
