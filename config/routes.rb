DataMigration::Engine.routes.draw do
  # Devise routes for DataMigrationUser
  devise_for :users, class_name: 'DataMigrationUser',
                     controllers: {
                       sessions: 'users/sessions'
                     },
                     path: '',
                     path_names: {
                       sign_in: 'login',
                       sign_out: 'logout'
                     },
                     skip: [:registrations]

  # Define root path with devise_scope
  devise_scope :user do
    root to: 'users/sessions#new'

    # Registration routes for password changes only (edit/update)
    resource :registration,
             only: %i[edit update],
             path: 'users',
             path_names: { edit: 'password/edit' },
             controller: 'devise/registrations',
             as: :user_registration
  end

  # Authenticated routes (require login)
  authenticate :user do
    get '/dashboard', to: 'data_migration/migration_plans#index', as: :authenticated_root

    # User management (admin only)
    resources :users, except: [:show], controller: 'data_migration/users'

    # Migration Plans and Steps
    resources :migration_plans, controller: 'data_migration/migration_plans' do
      member do
        get :export_config
      end

      collection do
        post :import_config
      end

      resources :migration_steps, except: [:index], controller: 'data_migration/migration_steps'

      get 'export/new', to: 'data_migration/exports#new', as: :new_export
      post 'export', to: 'data_migration/exports#create', as: :export

      get 'import/new', to: 'data_migration/imports#new', as: :new_import
      post 'import', to: 'data_migration/imports#create', as: :import
    end

    # Migration Executions
    resources :migration_executions, only: %i[index show], controller: 'data_migration/migration_executions' do
      member do
        get :download
      end
    end
  end
end
