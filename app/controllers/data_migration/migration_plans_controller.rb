module DataMigration
  class MigrationPlansController < ApplicationController
    include DataMigration::PunditAuthorization

    before_action :set_migration_plan, only: %i[show edit update destroy export_config]

    def index
      @migration_plans = policy_scope(MigrationPlan).ordered_by_name
    end

    def show
      authorize @migration_plan
    end

    def new
      @migration_plan = MigrationPlan.new
      authorize @migration_plan
    end

    def create
      @migration_plan = MigrationPlan.new(migration_plan_params)
      authorize @migration_plan

      if @migration_plan.save
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration plan was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @migration_plan
    end

    def update
      authorize @migration_plan

      if @migration_plan.update(migration_plan_params)
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", notice: 'Migration plan was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @migration_plan

      if @migration_plan.destroy
        redirect_to "/data_migration/migration_plans", notice: 'Migration plan was successfully destroyed.'
      else
        redirect_to "/data_migration/migration_plans/#{@migration_plan.id}", alert: 'Cannot delete migration plan with existing executions.'
      end
    end

    def export_config
      authorize @migration_plan

      service = MigrationPlans::ExportConfigService.new(@migration_plan)
      json_config = service.call

      send_data json_config,
                filename: "#{@migration_plan.name.parameterize}_config.json",
                type: 'application/json',
                disposition: 'attachment'
    end

    def import_config
      authorize MigrationPlan.new

      unless params[:config_file].present?
        redirect_to "/data_migration/migration_plans", alert: 'Please select a configuration file to import.'
        return
      end

      config_json = params[:config_file].read
      service = MigrationPlans::ImportConfigService.new(config_json, current_user)

      imported_plan = service.call

      if service.success? && imported_plan
        redirect_to "/data_migration/migration_plans/#{imported_plan.id}", notice: 'Migration plan configuration imported successfully!'
      else
        redirect_to "/data_migration/migration_plans", alert: "Import failed: #{service.errors.join(', ')}"
      end
    end

    private

    def set_migration_plan
      @migration_plan = MigrationPlan.find(params[:id])
    end

    def migration_plan_params
      params.require(:migration_plan).permit(:name, :description, settings: [])
    end
  end
end
