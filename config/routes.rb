DataMigration::Engine.routes.draw do
  # Devise routes (at engine root level)
  devise_for :users, class_name: "User"

  # All other routes under data_migration module
  scope module: 'data_migration' do
    # Root path
    root "migration_plans#index"

    # Migration Plans and Steps
    resources :migration_plans do
      resources :migration_steps

      # Export and Import operations for a specific plan
      post 'export', to: 'exports#create', as: :export
      get 'import/new', to: 'imports#new', as: :new_import
      post 'import', to: 'imports#create', as: :import
    end

    # Migration Executions (history and monitoring)
    resources :migration_executions, only: [:index, :show] do
      member do
        get :download
      end
    end

    # User management (admin only)
    resources :users, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :change_role
      end
    end
  end
end
