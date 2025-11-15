# Configure Warden to work within the engine scope
Warden::Manager.after_set_user do |user, auth, opts|
  scope = opts[:scope]
  auth.cookies.signed["#{scope}.id"] = user.id
  auth.cookies.signed["#{scope}.expires_at"] = 30.minutes.from_now
end

# Custom failure app that redirects within the engine
Warden::Manager.before_failure do |env, opts|
  # Set the script name to the engine mount point
  env['SCRIPT_NAME'] = '/data_migration' unless env['SCRIPT_NAME']&.start_with?('/data_migration')
end