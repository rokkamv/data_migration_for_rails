require 'devise'
require 'pundit'
require 'sidekiq'
require 'zip'

module DataMigration
  class Engine < ::Rails::Engine
    # Mountable engine - does NOT use isolate_namespace
    # This allows the engine to integrate with the host app's models

    # Ensure engine's app directories are autoloaded
    config.autoload_paths += %W[
      #{config.root}/app/controllers
      #{config.root}/app/models
      #{config.root}/app/policies
      #{config.root}/app/services
      #{config.root}/app/jobs
    ]

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end
