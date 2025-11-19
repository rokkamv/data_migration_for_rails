# Create initial admin user for Data Migration engine
unless DataMigrationUser.exists?(email: 'admin@datamigration.local')
  admin_user = DataMigrationUser.create!(
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
  admin_user = DataMigrationUser.find_by(email: 'admin@datamigration.local')
  puts "ℹ️  Admin user already exists"
end

# Create test MigrationPlan and MigrationSteps
if admin_user && MigrationPlan.count == 0
  puts "\n📋 Creating test migration plans..."

  # Plan 1: Company Migration (simple, no dependencies)
  company_plan = MigrationPlan.create!(
    name: 'Company Migration',
    description: 'Migrate all companies with basic filtering',
    user: admin_user
  )

  MigrationStep.create!(
    migration_plan: company_plan,
    source_model_name: 'Company',
    sequence: 1,
    filter_query: '',
    column_overrides: {}.to_json
  )

  puts "  ✅ Created 'Company Migration' plan with 1 step"

  # Plan 2: Employee Migration (with dependencies)
  employee_plan = MigrationPlan.create!(
    name: 'Employee Migration with Dependencies',
    description: 'Migrate employees with department associations',
    user: admin_user
  )

  # Step 1: Migrate departments first
  department_step = MigrationStep.create!(
    migration_plan: employee_plan,
    source_model_name: 'Department',
    sequence: 1,
    filter_query: 'where(id: Employee.select(:department_id).distinct)',
    column_overrides: {}.to_json
  )

  # Step 2: Migrate employees (depends on departments)
  employee_step = MigrationStep.create!(
    migration_plan: employee_plan,
    source_model_name: 'Employee',
    sequence: 2,
    dependee_id: department_step.id,
    dependee_attribute_mapping: { department_id: 'id' }.to_json,
    filter_query: '',
    column_overrides: {}.to_json,
    association_overrides: { department_id: 'MAPPED' }.to_json
  )

  puts "  ✅ Created 'Employee Migration with Dependencies' plan with 2 steps"

  # Plan 3: Complex Multi-Step Migration
  complex_plan = MigrationPlan.create!(
    name: 'Complex Multi-Model Migration',
    description: 'Full migration with multiple dependencies and associations',
    user: admin_user
  )

  # Step 1: Companies
  companies_step = MigrationStep.create!(
    migration_plan: complex_plan,
    source_model_name: 'Company',
    sequence: 1,
    filter_query: 'where("created_at > ?", "2024-01-01")',
    column_overrides: {}.to_json
  )

  # Step 2: Departments
  departments_step = MigrationStep.create!(
    migration_plan: complex_plan,
    source_model_name: 'Department',
    sequence: 2,
    filter_query: '',
    column_overrides: {}.to_json
  )

  # Step 3: Employees (depends on departments)
  employees_step = MigrationStep.create!(
    migration_plan: complex_plan,
    source_model_name: 'Employee',
    sequence: 3,
    dependee_id: departments_step.id,
    dependee_attribute_mapping: { department_id: 'id' }.to_json,
    filter_query: '',
    association_overrides: { department_id: 'MAPPED' }.to_json
  )

  puts "  ✅ Created 'Complex Multi-Model Migration' plan with 3 steps"

  puts "\n✅ Test migration plans created successfully!"
  puts "   Total plans: #{MigrationPlan.count}"
  puts "   Total steps: #{MigrationStep.count}"
elsif MigrationPlan.count > 0
  puts "\nℹ️  Migration plans already exist (#{MigrationPlan.count} plans, #{MigrationStep.count} steps)"
end
