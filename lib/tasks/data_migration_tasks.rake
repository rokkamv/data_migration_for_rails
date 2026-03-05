# frozen_string_literal: true

namespace :data_migration do
  desc 'Install Data Migration engine (migrations + seed admin user)'
  task install: :environment do
    puts 'Installing Data Migration engine...'
    puts '=' * 80

    # Copy migrations
    puts "
📦 Copying migrations..."
    Rake::Task['data_migration_engine:install:migrations'].invoke

    # Run migrations
    puts "
🔨 Running migrations..."
    Rake::Task['db:migrate'].invoke

    # Seed admin user
    puts "
👤 Creating admin user..."
    DataMigration::Engine.load_seed

    puts "\n#{'=' * 80}"
    puts '✅ Installation complete!'
    puts "
📋 Next Steps:"
    puts "1. Add to routes.rb: mount DataMigration::Engine => '/data_migration'"
    puts '2. Configure Sidekiq in config/application.rb'
    puts '3. Start Redis and Sidekiq'
    puts '4. Visit /data_migration'
    puts '5. Login with: admin@datamigration.local / password'
    puts '6. ⚠️  CHANGE THE ADMIN PASSWORD IMMEDIATELY!'
  end

  desc 'Seed admin user'
  task seed: :environment do
    DataMigration::Engine.load_seed
  end
end
