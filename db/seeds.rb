# frozen_string_literal: true

# Create initial admin user for Data Migration engine
if DataMigrationUser.exists?(email: 'admin@datamigration.local')
  puts 'ℹ️  Admin user already exists'
else
  DataMigrationUser.create!(
    name: 'Administrator',
    email: 'admin@datamigration.local',
    password: 'password',
    password_confirmation: 'password',
    role: :admin
  )

  puts '✅ Created admin user:'
  puts '   Email: admin@datamigration.local'
  puts '   Password: password'
  puts '   ⚠️  CHANGE THIS PASSWORD IMMEDIATELY IN PRODUCTION!'
end
