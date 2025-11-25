# Create initial admin user for Data Migration engine
unless DataMigrationUser.exists?(email: 'admin@datamigration.local')
  DataMigrationUser.create!(
    name: 'Administrator',
    email: 'admin@datamigration.local',
    password: 'password',
    password_confirmation: 'password',
    role: :admin
  )

  puts "✅ Created admin user:"
  puts "   Email: admin@datamigration.local"
  puts "   Password: password"
  puts "   ⚠️  CHANGE THIS PASSWORD IMMEDIATELY IN PRODUCTION!"
else
  puts "ℹ️  Admin user already exists"
end
