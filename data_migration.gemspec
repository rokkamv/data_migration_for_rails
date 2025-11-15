require_relative "lib/data_migration/version"

Gem::Specification.new do |spec|
  spec.name        = "data_migration"
  spec.version     = DataMigration::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/yourusername/data_migration"
  spec.summary     = "Rails engine for migrating data between environments"
  spec.description = "A web-based tool for exporting and importing Rails application data with audit trails and role-based access control."
  spec.license     = "GPL-3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 7.1.5"
  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "pundit", "~> 2.3"
  spec.add_dependency "sidekiq", "~> 7.0"
  spec.add_dependency "redis", ">= 4.0.1"
  spec.add_dependency "rubyzip", "~> 2.3"
  spec.add_dependency "bcrypt", "~> 3.1.7"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "faker"
end
