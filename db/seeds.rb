# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."
puts

# Check if admin user already exists
existing_admin = User.find_by(role: :admin)

if existing_admin
  puts "✓ Admin user already exists: #{existing_admin.email}"
  puts "  No changes made."
else
  # Get admin credentials
  admin_email = ENV['ADMIN_EMAIL']
  admin_password = ENV['ADMIN_PASSWORD']

  # Prompt for email if not provided
  if admin_email.blank?
    print "Enter admin email address: "
    admin_email = $stdin.gets.chomp
  end

  # Prompt for password if not provided
  if admin_password.blank?
    print "Enter admin password (min 6 characters): "
    admin_password = $stdin.gets.chomp

    print "Confirm admin password: "
    password_confirmation = $stdin.gets.chomp

    unless admin_password == password_confirmation
      puts "❌ Passwords do not match. Aborting."
      exit(1)
    end

    if admin_password.length < 6
      puts "❌ Password must be at least 6 characters. Aborting."
      exit(1)
    end
  end

  # Create admin user
  admin = User.new(
    email: admin_email,
    password: admin_password,
    password_confirmation: admin_password,
    role: :admin
  )

  admin.skip_confirmation! # Skip email verification

  if admin.save
    puts
    puts "✅ Admin user created successfully!"
    puts "   Email: #{admin_email}"
    puts "   Role: Admin"
    puts
    puts "⚠️  You can now login with these credentials."
  else
    puts
    puts "❌ Failed to create admin user:"
    admin.errors.full_messages.each do |error|
      puts "   - #{error}"
    end
    exit(1)
  end
end

# Create sample users for development environment
if Rails.env.development? && !User.exists?(email: 'operator@example.com')
  puts
  puts "Creating sample users for development..."

  operator = User.new(
    email: 'operator@example.com',
    password: 'Operator123!',
    password_confirmation: 'Operator123!',
    role: :operator
  )
  operator.skip_confirmation!
  operator.save!
  puts "✓ Created operator@example.com (password: Operator123!)"

  viewer = User.new(
    email: 'viewer@example.com',
    password: 'Viewer123!',
    password_confirmation: 'Viewer123!',
    role: :viewer
  )
  viewer.skip_confirmation!
  viewer.save!
  puts "✓ Created viewer@example.com (password: Viewer123!)"
end

puts
puts "🎉 Seeding completed!"
